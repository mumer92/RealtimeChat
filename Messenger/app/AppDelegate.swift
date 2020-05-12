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

import UIKit
import CoreSpotlight
import OneSignal
import RealmSwift
import Sinch

//-------------------------------------------------------------------------------------------------------------------------------------------------
let realm = try! Realm()
let falsepredicate = NSPredicate(value: false)

//-------------------------------------------------------------------------------------------------------------------------------------------------
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
	var tabBarController: UITabBarController!

	var chatsView: ChatsView!
	var peopleView: PeopleView!
	var groupsView: GroupsView!
	var settingsView: SettingsView!

	var client: SINClient?
	var push: SINManagedPush?
	var callKitProvider: CallKitProvider?

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

		//-----------------------------------------------------------------------------------------------------------------------------------------
		// SyncEngine initialization
		//-----------------------------------------------------------------------------------------------------------------------------------------
		SyncEngine.initBackend()
		SyncEngine.initUpdaters()
		SyncEngine.initObservers()

		//-----------------------------------------------------------------------------------------------------------------------------------------
		// Push notification initialization
		//-----------------------------------------------------------------------------------------------------------------------------------------
		let authorizationOptions: UNAuthorizationOptions = [.sound, .alert, .badge]
		UNUserNotificationCenter.current().requestAuthorization(options: authorizationOptions, completionHandler: { granted, error in
			if (error == nil) {
				DispatchQueue.main.async {
					UIApplication.shared.registerForRemoteNotifications()
				}
			}
		})

		//-----------------------------------------------------------------------------------------------------------------------------------------
		// OneSignal initialization
		//-----------------------------------------------------------------------------------------------------------------------------------------
		OneSignal.initWithLaunchOptions(launchOptions, appId: ONESIGNAL_APPID, handleNotificationReceived: nil,
										handleNotificationAction: nil, settings: [kOSSettingsKeyAutoPrompt: false])
		OneSignal.setLogLevel(ONE_S_LOG_LEVEL.LL_NONE, visualLevel: ONE_S_LOG_LEVEL.LL_NONE)
		OneSignal.inFocusDisplayType = OSNotificationDisplayType.none

		//-----------------------------------------------------------------------------------------------------------------------------------------
		// Manager initialization
		//-----------------------------------------------------------------------------------------------------------------------------------------
		_ = ChatManager.shared
		_ = Connectivity.shared
		_ = LocationManager.shared

		//-----------------------------------------------------------------------------------------------------------------------------------------
		// MediaUploader initialization
		//-----------------------------------------------------------------------------------------------------------------------------------------
		_ = MediaUploader.shared

		//-----------------------------------------------------------------------------------------------------------------------------------------
		// UI initialization
		//-----------------------------------------------------------------------------------------------------------------------------------------
		window = UIWindow(frame: UIScreen.main.bounds)

		chatsView = ChatsView(nibName: "ChatsView", bundle: nil)
		peopleView = PeopleView(nibName: "PeopleView", bundle: nil)
		groupsView = GroupsView(nibName: "GroupsView", bundle: nil)
		settingsView = SettingsView(nibName: "SettingsView", bundle: nil)

		let navController1 = NavigationController(rootViewController: chatsView)
		let navController2 = NavigationController(rootViewController: peopleView)
		let navController3 = NavigationController(rootViewController: groupsView)
		let navController4 = NavigationController(rootViewController: settingsView)

		tabBarController = UITabBarController()
		tabBarController.viewControllers = [navController1, navController2, navController3, navController4]
		tabBarController.tabBar.isTranslucent = false
		tabBarController.selectedIndex = Int(DEFAULT_TAB)

		window?.rootViewController = tabBarController
		window?.makeKeyAndVisible()

		_ = chatsView.view
		_ = peopleView.view
		_ = groupsView.view
		_ = settingsView.view

		//-----------------------------------------------------------------------------------------------------------------------------------------
		// Sinch initialization
		//-----------------------------------------------------------------------------------------------------------------------------------------
		push = Sinch.managedPush(with: .development)
		push?.delegate = self
		push?.setDesiredPushType(SINPushTypeVoIP)

		callKitProvider = CallKitProvider()

		NotificationCenter.addObserver(target: self, selector: #selector(sinchLogInUser), name: NOTIFICATION_APP_STARTED)
		NotificationCenter.addObserver(target: self, selector: #selector(sinchLogInUser), name: NOTIFICATION_USER_LOGGED_IN)
		NotificationCenter.addObserver(target: self, selector: #selector(sinchLogOutUser), name: NOTIFICATION_USER_LOGGED_OUT)

		return true
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func applicationWillResignActive(_ application: UIApplication) {

	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func applicationDidEnterBackground(_ application: UIApplication) {

		LocationManager.stop()

		Persons.update(lastTerminate: Date().timestamp())
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func applicationWillEnterForeground(_ application: UIApplication) {

	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func applicationDidBecomeActive(_ application: UIApplication) {

		LocationManager.start()
		MediaManager.cleanupExpired()

		NotificationCenter.post(notification: NOTIFICATION_APP_STARTED)

		DispatchQueue.main.async(after: 0.5) {
			Persons.update(lastActive: Date().timestamp())
			Persons.update(oneSignalId: PushNotification.oneSignalId())
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func applicationWillTerminate(_ application: UIApplication) {

	}

	// MARK: - CoreSpotlight methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {

		if (userActivity.activityType == CSSearchableItemActionType) {
			if let userId = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
				if (AuthUser.userId() != "") {
					peopleView.actionUser(userId: userId)
					return true
				}
			}
		}
		return false
	}

	// MARK: - Sinch user methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc func sinchLogInUser() {

		let userId = AuthUser.userId()

		if (userId == "")	{ return }
		if (client != nil)	{ return }

		client = Sinch.client(withApplicationKey: SINCH_KEY, applicationSecret: SINCH_SECRET, environmentHost: SINCH_HOST, userId: userId)
		client?.delegate = self
		client?.call().delegate = self
		client?.setSupportCalling(true)
		client?.enableManagedPushNotifications()
		callKitProvider?.setClient(client)
		client?.start()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc func sinchLogOutUser() {

		client?.terminateGracefully()
		client = nil
	}

	// MARK: - Home screen dynamic quick action methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {

		if (AuthUser.userId() != "") {
			if (shortcutItem.type == "newchat") {
				chatsView.actionNewChat()
			}
			if (shortcutItem.type == "newgroup") {
				groupsView.actionNewGroup()
			}
			if (shortcutItem.type == "recentuser") {
				if let userInfo = shortcutItem.userInfo as? [String: String] {
					if let userId = userInfo["userId"] {
						chatsView.actionRecentUser(userId: userId)
					}
				}
			}
		}

		if (shortcutItem.type == "shareapp") {
			if let topViewController = topViewController() {
				var shareitems: [AnyHashable] = []
				shareitems.append(TEXT_SHARE_APP)
				let activityView = UIActivityViewController(activityItems: shareitems, applicationActivities: nil)
				topViewController.present(activityView, animated: true)
			}
		}
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func topViewController() -> UIViewController? {

		let keyWindow = UIApplication.shared.windows.first { $0.isKeyWindow }
		var viewController = keyWindow?.rootViewController

		while (viewController?.presentedViewController != nil) {
			viewController = viewController?.presentedViewController
		}
		return viewController
	}
}

// MARK: - SINClientDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension AppDelegate: SINClientDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func clientDidStart(_ client: SINClient!) {

	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func clientDidFail(_ client: SINClient!, error: Error!) {

	}
}

// MARK: - SINCallClientDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension AppDelegate: SINCallClientDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func client(_ client: SINCallClient!, willReceiveIncomingCall call: SINCall!) {

		callKitProvider?.insertCall(call: call)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func client(_ client: SINCallClient!, didReceiveIncomingCall call: SINCall!) {

		callKitProvider?.insertCall(call: call)

		callKitProvider?.reportNewIncomingCall(call: call)
	}
}

// MARK: - SINManagedPushDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension AppDelegate: SINManagedPushDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func managedPush(_ managedPush: SINManagedPush!, didReceiveIncomingPushWithPayload payload: [AnyHashable: Any]!, forType pushType: String!) {

		callKitProvider?.didReceivePush(withPayload: payload)

		DispatchQueue.main.async {
			self.sinchLogInUser()
			self.client?.relayRemotePushNotification(payload)
			self.push?.didCompleteProcessingPushPayload(payload)
		}
	}
}
