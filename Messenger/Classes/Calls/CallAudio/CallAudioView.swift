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

//-------------------------------------------------------------------------------------------------------------------------------------------------
class CallAudioView: UIViewController {

	@IBOutlet var imageUser: UIImageView!
	@IBOutlet var labelInitials: UILabel!
	@IBOutlet var labelName: UILabel!
	@IBOutlet var labelStatus: UILabel!
	@IBOutlet var viewButtons: UIView!
	@IBOutlet var buttonMute: UIButton!
	@IBOutlet var buttonSpeaker: UIButton!
	@IBOutlet var buttonVideo: UIButton!
	@IBOutlet var viewButtons1: UIView!
	@IBOutlet var viewButtons2: UIView!
	@IBOutlet var viewEnded: UIView!

	private var person: Person!
	private var timer: Timer?

	private var incoming = false
	private var outgoing = false
	private var muted = false
	private var speaker = false

	private var call: SINCall?
	private var audioController: SINAudioController?

	//---------------------------------------------------------------------------------------------------------------------------------------------
	init(call: SINCall?) {

		super.init(nibName: nil, bundle: nil)

		self.isModalInPresentation = true
		self.modalPresentationStyle = .fullScreen

		let app = UIApplication.shared.delegate as? AppDelegate

		self.call = call
		call?.delegate = self

		audioController = app?.client?.audioController()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	init(userId: String) {

		super.init(nibName: nil, bundle: nil)

		self.isModalInPresentation = true
		self.modalPresentationStyle = .fullScreen

		let app = UIApplication.shared.delegate as? AppDelegate

		call = app?.client?.call().callUser(withId: userId, headers: ["name": Persons.fullname()])
		call?.delegate = self

		audioController = app?.client?.audioController()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	required init?(coder aDecoder: NSCoder) {

		super.init(coder: aDecoder)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func viewDidLoad() {

		super.viewDidLoad()

		audioController?.unmute()
		audioController?.disableSpeaker()

		buttonMute.setImage(UIImage(named: "callaudio_mute1"), for: .normal)
		buttonMute.setImage(UIImage(named: "callaudio_mute1"), for: .highlighted)

		buttonSpeaker.setImage(UIImage(named: "callaudio_speaker1"), for: .normal)
		buttonSpeaker.setImage(UIImage(named: "callaudio_speaker1"), for: .highlighted)

		buttonVideo.setImage(UIImage(named: "callaudio_video1"), for: .normal)
		buttonVideo.setImage(UIImage(named: "callaudio_video1"), for: .highlighted)

		incoming = (call?.direction == .incoming)
		outgoing = (call?.direction == .outgoing)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func viewWillAppear(_ animated: Bool) {

		super.viewWillAppear(animated)

		if (outgoing) { updateDetails1() }
		if (incoming) { updateDetails2() }

		loadPerson()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override var supportedInterfaceOrientations: UIInterfaceOrientationMask {

		return .portrait
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {

		return .portrait
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override var shouldAutorotate: Bool {

		return false
	}

	// MARK: - Realm methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func loadPerson() {

		if let remoteUserId = call?.remoteUserId {
			person = realm.object(ofType: Person.self, forPrimaryKey: remoteUserId)

			labelInitials.text = person.initials()
			MediaDownload.startUser(person.objectId, pictureAt: person.pictureAt) { image, error in
				if (error == nil) {
					self.imageUser.image = image?.square(to: 70)
					self.labelInitials.text = nil
				}
			}

			labelName.text = person.fullname
		}
	}

	// MARK: - Timer methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func timerStart() {

		timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
			self.updateStatus()
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func timerStop() {

		timer?.invalidate()
		timer = nil
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func updateStatus() {

		if let date = call?.details.establishedTime {
			let interval = Date().timeIntervalSince(date)
			let seconds = Int(interval) % 60
			let minutes = Int(interval) / 60
			labelStatus.text = String(format: "%02d:%02d", minutes, seconds)
		}
	}

	// MARK: - User actions
	//---------------------------------------------------------------------------------------------------------------------------------------------
	@IBAction func actionMute(_ sender: Any) {

		if (muted) {
			muted = false
			buttonMute.setImage(UIImage(named: "callaudio_mute1"), for: .normal)
			buttonMute.setImage(UIImage(named: "callaudio_mute1"), for: .highlighted)
			audioController?.unmute()
		} else {
			muted = true
			buttonMute.setImage(UIImage(named: "callaudio_mute2"), for: .normal)
			buttonMute.setImage(UIImage(named: "callaudio_mute2"), for: .highlighted)
			audioController?.mute()
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	@IBAction func actionSpeaker(_ sender: Any) {

		if (speaker) {
			speaker = false
			buttonSpeaker.setImage(UIImage(named: "callaudio_speaker1"), for: .normal)
			buttonSpeaker.setImage(UIImage(named: "callaudio_speaker1"), for: .highlighted)
			audioController?.disableSpeaker()
		} else {
			speaker = true
			buttonSpeaker.setImage(UIImage(named: "callaudio_speaker2"), for: .normal)
			buttonSpeaker.setImage(UIImage(named: "callaudio_speaker2"), for: .highlighted)
			audioController?.enableSpeaker()
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	@IBAction func actionVideo(_ sender: Any) {

	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	@IBAction func actionHangup(_ sender: Any) {

		call?.hangup()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	@IBAction func actionAnswer(_ sender: Any) {

		call?.answer()
	}

	// MARK: - Helper methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func updateDetails1() {

		labelStatus.text = "Calling..."

		viewButtons.isHidden = incoming
		viewButtons1.isHidden = outgoing
		viewButtons2.isHidden = incoming

		viewEnded.isHidden = true
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func updateDetails2() {

		labelStatus.text = "00:00"

		viewButtons.isHidden = false
		viewButtons1.isHidden = true
		viewButtons2.isHidden = false

		viewEnded.isHidden = true
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func updateDetails3() {

		labelStatus.text = "Ended"

		viewEnded.isHidden = false
	}
}

// MARK: - SINCallDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension CallAudioView: SINCallDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func callDidProgress(_ call: SINCall?) {

		audioController?.startPlayingSoundFile(Dir.application("call_ringback.wav"), loop: true)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func callDidEstablish(_ call: SINCall?) {

		timerStart()
		audioController?.stopPlayingSoundFile()
		updateDetails2()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func callDidEnd(_ call: SINCall?) {

		timerStop()
		audioController?.stopPlayingSoundFile()
		updateDetails3()

		DispatchQueue.main.async(after: 1.5) {
			self.dismiss(animated: true)
		}
	}
}
