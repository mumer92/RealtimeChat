//
// Copyright (c) 2020 Related Code - http://relatedcode.com
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Sinch
import CallKit

//-------------------------------------------------------------------------------------------------------------------------------------------------
class CallKitProvider: NSObject {

	private var client: SINClient!
	private var cxprovider: CXProvider!
	private var callController = CXCallController()

	private var name = ""
	private var calls: [UUID: SINCall] = [:]

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override init() {

		super.init()

		let configuration = CXProviderConfiguration(localizedName: "related.chat")
		configuration.supportsVideo = true
		configuration.maximumCallGroups = 1
		configuration.maximumCallsPerCallGroup = 1
		configuration.includesCallsInRecents = true

		cxprovider = CXProvider(configuration: configuration)
		cxprovider.setDelegate(self, queue: nil)

		let nameDidProgress		= NSNotification.Name.SINCallDidProgress
		let nameDidEstablish	= NSNotification.Name.SINCallDidEstablish
		let nameDidEnd			= NSNotification.Name.SINCallDidEnd

		NotificationCenter.default.addObserver(self, selector: #selector(callDidEnd(notification:)), name: nameDidEnd, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(callDidProgress(notification:)), name: nameDidProgress, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(callDidEstablish(notification:)), name: nameDidEstablish, object: nil)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func setClient(_ client: SINClient?) {

		self.client = client
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func didReceivePush(withPayload payload: [AnyHashable: Any]?) {

		if let notificationResult = SINPushHelper.queryPushNotificationPayload(payload) {
			if notificationResult.isCall() {
				if let callResult = notificationResult.call() {
					if let name = callResult.headers["name"] as? String {
						self.name = name
					}
					DispatchQueue.main.sync {
						if (UIApplication.shared.applicationState != .active) {
							reportNewIncomingCall(callResult)
						}
					}
				}
			}
		}
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func reportNewIncomingCall(call: SINCall) {

		guard let callUUID = UUID(uuidString: call.callId) else { return }

		let update = CXCallUpdate()
		update.remoteHandle = CXHandle(type: .generic, value: name)
		update.hasVideo = call.details.isVideoOffered

		cxprovider.reportNewIncomingCall(with: callUUID, update: update) { error in
			if let error = error {
				print(error.localizedDescription)
			}
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func reportNewIncomingCall(_ result: SINCallNotificationResult) {

		guard let callUUID = UUID(uuidString: result.callId) else { return }

		let update = CXCallUpdate()
		update.remoteHandle = CXHandle(type: .generic, value: name)
		update.hasVideo = result.isVideoOffered

		cxprovider.reportNewIncomingCall(with: callUUID, update: update) { error in
			if let error = error {
				print(error.localizedDescription)
			}
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func reportCallProgress(call: SINCall) {

		guard let callUUID = UUID(uuidString: call.callId) else { return }
		guard let name = call.headers["name"] as? String else { return }

		let handle = CXHandle(type: .generic, value: name)
		let startCallAction = CXStartCallAction(call: callUUID, handle: handle)

		if let details = call.details {
			startCallAction.isVideo = details.isVideoOffered
		}

		let transaction = CXTransaction(action: startCallAction)
		callController.request(transaction) { error in
			if let error = error {
				print(error.localizedDescription)
			}
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func reportCallEstablish(call: SINCall) {

		guard let callUUID = UUID(uuidString: call.callId) else { return }

		cxprovider.reportOutgoingCall(with: callUUID, connectedAt: Date())
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func reportCallEnded(call: SINCall) {

		guard let callUUID = UUID(uuidString: call.callId) else { return }

		var reason = CXCallEndedReason.unanswered

		switch call.details.endCause {
			case SINCallEndCause.error:	 reason = .failed
			case SINCallEndCause.denied: reason = .remoteEnded
			case SINCallEndCause.hungUp: reason = .remoteEnded
			default: break
		}

		cxprovider.reportCall(with: callUUID, endedAt: call.details.endedTime, reason: reason)
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func insertCall(call: SINCall) {

		if let callUUID = UUID(uuidString: call.callId) {
			calls[callUUID] = call
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func deleteCall(call: SINCall) {

		if let callUUID = UUID(uuidString: call.callId) {
			calls.removeValue(forKey: callUUID)
		}
	}

	// MARK: - SINCall notifications
	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc private func callDidProgress(notification: Notification) {

		if let call = notification.userInfo?[SINCallKey] as? SINCall {
			reportCallProgress(call: call)
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc private func callDidEstablish(notification: Notification) {

		if let call = notification.userInfo?[SINCallKey] as? SINCall {
			reportCallEstablish(call: call)
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc private func callDidEnd(notification: Notification) {

		if let call = notification.userInfo?[SINCallKey] as? SINCall {
			reportCallEnded(call: call)
			deleteCall(call: call)
		}
	}

	// MARK: - Helper methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func topViewController() -> UIViewController? {

		let keyWindow = UIApplication.shared.windows.first { $0.isKeyWindow }
		var viewController = keyWindow?.rootViewController

		while (viewController?.presentedViewController != nil) {
			viewController = viewController?.presentedViewController
		}
		return viewController
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
extension CallKitProvider: CXProviderDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func providerDidBegin(_ provider: CXProvider) {

	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func providerDidReset(_ provider: CXProvider) {

	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {

		client.call().provider(provider, didActivate: audioSession)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {

		client.call().provider(provider, didDeactivate: audioSession)
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func provider(_ provider: CXProvider, perform action: CXStartCallAction) {

		guard let callUUID = UUID(uuidString: action.callUUID.uuidString) else { return }

		client.audioController().configureAudioSessionForCallKitCall()

		provider.reportOutgoingCall(with: callUUID, connectedAt: Date())
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {

		guard let call = calls[action.callUUID] else { return }

		call.answer()

		client.audioController().configureAudioSessionForCallKitCall()

		if (call.details.isVideoOffered) {
			if let topViewController = topViewController() {
				let callVideoView = CallVideoView(call: call)
				topViewController.present(callVideoView, animated: false)
			}
		} else {
			if let topViewController = topViewController() {
				let callAudioView = CallAudioView(call: call)
				topViewController.present(callAudioView, animated: false)
			}
		}

		action.fulfill()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func provider(_ provider: CXProvider, perform action: CXEndCallAction) {

		guard let call = calls[action.callUUID] else { return }

		call.hangup()

		action.fulfill()
	}
}
