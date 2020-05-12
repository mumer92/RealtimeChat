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

import RealmSwift
import ProgressHUD
import CoreLocation
import SoundManager

//-------------------------------------------------------------------------------------------------------------------------------------------------
class RCPrivateChatView: RCMessagesView, UIGestureRecognizerDelegate {

	private var chatId = ""
	private var recipientId = ""
	private var isBlocker = false

	private var detail: Detail?
	private var details = realm.objects(Detail.self).filter(falsepredicate)
	private var messages = realm.objects(Message.self).filter(falsepredicate)

	private var tokenDetails: NotificationToken? = nil
	private var tokenMessages: NotificationToken? = nil

	private var rcmessages: [String: RCMessage] = [:]
	private var avatarImages: [String: UIImage] = [:]

	private var messageToDisplay: Int = 12

	private var typingCounter: Int = 0
	private var lastRead: Int64 = 0

	private var indexForward: IndexPath?

	//---------------------------------------------------------------------------------------------------------------------------------------------
	init(chatId: String, recipientId: String) {

		super.init(nibName: "RCMessagesView", bundle: nil)

		self.chatId = chatId
		self.recipientId = recipientId

		isBlocker = Blockeds.isBlocker(recipientId)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	required init?(coder aDecoder: NSCoder) {

		super.init(coder: aDecoder)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func viewDidLoad() {

		super.viewDidLoad()

		navigationController?.interactivePopGestureRecognizer?.delegate = self

		if (isBlocker) {
			messageInputBar.isUserInteractionEnabled = false
		}

		let wallpaper = Persons.wallpaper()
		if (wallpaper.count != 0) {
			tableView.backgroundView = UIImageView(image: UIImage(named: wallpaper))
			tableView.backgroundView?.contentMode = .scaleAspectFill
		}

		messageInputBar.backgroundView.backgroundColor = .systemBackground
		messageInputBar.inputTextView.backgroundColor = .systemBackground

		loadDetail()
		loadDetails()
		loadMessages()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func viewWillAppear(_ animated: Bool) {

		super.viewWillAppear(animated)

		updateTitleDetails()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func viewDidDisappear(_ animated: Bool) {

		super.viewDidDisappear(animated)

		if (isMovingFromParent) {
			actionCleanup()
		}
	}

	// MARK: - Realm methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func loadDetail() {

		let predicate = NSPredicate(format: "chatId == %@ AND userId == %@", chatId, AuthUser.userId())
		detail = realm.objects(Detail.self).filter(predicate).first
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func loadDetails() {

		let predicate = NSPredicate(format: "chatId == %@ AND userId != %@", chatId, AuthUser.userId())
		details = realm.objects(Detail.self).filter(predicate)

		details.safeObserve({ changes in
			self.refreshTyping()
			self.refreshLastRead()
		}, completion: { token in
			self.tokenDetails = token
		})
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func loadMessages() {

		let predicate = NSPredicate(format: "chatId == %@ AND isDeleted == NO", chatId)
		messages = realm.objects(Message.self).filter(predicate).sorted(byKeyPath: "createdAt")

		messages.safeObserve({ changes in
			switch changes {
				case .initial:
					self.refreshLoadEarlier()
					self.refreshTableView()
					self.scrollToBottom()
				case .update(_, let delete, let insert, _):
					self.messageToDisplay -= delete.count
					self.messageToDisplay += insert.count
					self.refreshTableView()
					if (insert.count != 0) {
						self.scrollToBottom()
						self.playIncoming()
					}
				default: break
			}
		}, completion: { token in
			self.tokenMessages = token
		})
	}

	// MARK: - Message methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func messageTotalCount() -> Int {

		return messages.count
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func messageLoadedCount() -> Int {

		return min(messageToDisplay, messageTotalCount())
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func messageAt(_ indexPath: IndexPath) -> Message {

		let offset = messageTotalCount() - messageLoadedCount()
		let index = indexPath.section + offset

		return messages[index]
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func rcmessageAt(_ indexPath: IndexPath) -> RCMessage {

		let message = messageAt(indexPath)

		if let rcmessage = rcmessages[message.objectId] {
			rcmessage.update(message)
			loadMedia(rcmessage)
			return rcmessage
		}

		let rcmessage = RCMessage(message: message)
		rcmessages[message.objectId] = rcmessage
		loadMedia(rcmessage)
		return rcmessage
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func loadMedia(_ rcmessage: RCMessage) {

		if (rcmessage.mediaStatus != MEDIASTATUS_UNKNOWN)	 { return }
		if (rcmessage.incoming) && (rcmessage.isMediaQueued) { return }
		if (rcmessage.incoming) && (rcmessage.isMediaFailed) { return }

		if (rcmessage.type == MESSAGE_PHOTO)	{ RCPhotoLoader.start(rcmessage, in: tableView)		}
		if (rcmessage.type == MESSAGE_VIDEO)	{ RCVideoLoader.start(rcmessage, in: tableView)		}
		if (rcmessage.type == MESSAGE_AUDIO)	{ RCAudioLoader.start(rcmessage, in: tableView)		}
		if (rcmessage.type == MESSAGE_LOCATION)	{ RCLocationLoader.start(rcmessage, in: tableView)	}
	}

	// MARK: - Avatar methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func avatarInitials(_ indexPath: IndexPath) -> String {

		let rcmessage = rcmessageAt(indexPath)
		return rcmessage.userInitials
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func avatarImage(_ indexPath: IndexPath) -> UIImage? {

		let rcmessage = rcmessageAt(indexPath)
		var imageAvatar = avatarImages[rcmessage.userId]

		if (imageAvatar == nil) {
			if let path = MediaDownload.pathUser(rcmessage.userId) {
				imageAvatar = UIImage.image(path, size: 30)
				avatarImages[rcmessage.userId] = imageAvatar
			}
		}

		if (imageAvatar == nil) {
			MediaDownload.startUser(rcmessage.userId, pictureAt: rcmessage.userPictureAt) { image, error in
				if (error == nil) {
					self.refreshTableView()
				}
			}
		}

		return imageAvatar
	}

	// MARK: - Header, Footer methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func textHeaderUpper(_ indexPath: IndexPath) -> String? {

		if (indexPath.section % 3 == 0) {
			let rcmessage = rcmessageAt(indexPath)
			return Convert.timestampToDayMonthTime(rcmessage.createdAt)
		} else {
			return nil
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func textHeaderLower(_ indexPath: IndexPath) -> String? {

		return nil
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func textFooterUpper(_ indexPath: IndexPath) -> String? {

		return nil
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func textFooterLower(_ indexPath: IndexPath) -> String? {

		let rcmessage = rcmessageAt(indexPath)
		if (rcmessage.outgoing) {
			let message = messageAt(indexPath)
			if (message.syncRequired)	{ return STATUS_QUEUED }
			if (message.isMediaQueued)	{ return STATUS_QUEUED }
			if (message.isMediaFailed)	{ return STATUS_FAILED }
			return (message.createdAt > lastRead) ? STATUS_SENT : STATUS_READ
		}
		return nil
	}

	// MARK: - Menu controller methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func menuItems(_ indexPath: IndexPath) -> [RCMenuItem]? {

		let menuItemCopy = RCMenuItem(title: "Copy", action: #selector(actionMenuCopy(_:)))
		let menuItemSave = RCMenuItem(title: "Save", action: #selector(actionMenuSave(_:)))
		let menuItemDelete = RCMenuItem(title: "Delete", action: #selector(actionMenuDelete(_:)))
		let menuItemForward = RCMenuItem(title: "Forward", action: #selector(actionMenuForward(_:)))

		menuItemCopy.indexPath = indexPath
		menuItemSave.indexPath = indexPath
		menuItemDelete.indexPath = indexPath
		menuItemForward.indexPath = indexPath

		let rcmessage = rcmessageAt(indexPath)

		var array: [RCMenuItem] = []

		if (rcmessage.type == MESSAGE_TEXT)		{ array.append(menuItemCopy) }
		if (rcmessage.type == MESSAGE_EMOJI)	{ array.append(menuItemCopy) }

		if (rcmessage.type == MESSAGE_PHOTO)	{ array.append(menuItemSave) }
		if (rcmessage.type == MESSAGE_VIDEO)	{ array.append(menuItemSave) }
		if (rcmessage.type == MESSAGE_AUDIO)	{ array.append(menuItemSave) }

		array.append(menuItemDelete)
		array.append(menuItemForward)

		return array
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {

		if (action == #selector(actionMenuCopy(_:)))	{ return true }
		if (action == #selector(actionMenuSave(_:)))	{ return true }
		if (action == #selector(actionMenuDelete(_:)))	{ return true }
		if (action == #selector(actionMenuForward(_:)))	{ return true }

		return false
	}

	// MARK: - Typing indicator methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func typingIndicatorUpdate() {

		typingCounter += 1
		detail?.update(typing: true)

		DispatchQueue.main.async(after: 2.0) {
			self.typingIndicatorStop()
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func typingIndicatorStop() {

		typingCounter -= 1
		if (typingCounter == 0) {
			detail?.update(typing: false)
		}
	}

	// MARK: - Title details methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func updateTitleDetails() {

		if let person = realm.object(ofType: Person.self, forPrimaryKey: recipientId) {
			labelTitle1.text = person.fullname
			labelTitle2.text = person.lastActiveText()
		}
	}

	// MARK: - Refresh methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func refreshLoadEarlier() {

		loadEarlierShow(messageToDisplay < messages.count)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func refreshTableView() {

		tableView.reloadData()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func scrollToBottom() {

		DispatchQueue.main.async(after: 0.1) {
			self.scrollToBottom(animated: true)
		}
		detail?.update(lastRead: Date().timestamp())
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func playIncoming() {

		if let message = messages.last {
			if (message.userId != AuthUser.userId()) {
				Audio.playMessageIncoming()
			}
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func refreshTyping() {

		var typing = false
		for detail in details {
			if (detail.typing) {
				typing = true
			}
		}
		self.typingIndicatorShow(typing)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func refreshLastRead() {

		for detail in details {
			if (detail.lastRead > lastRead) {
				lastRead = detail.lastRead
			}
		}
		refreshTableView()
	}

	// MARK: - Message send methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func messageSend(text: String?, photo: UIImage?, video: URL?, audio: String?) {

		Messages.send(chatId: chatId, text: text, photo: photo, video: video, audio: audio)

		Shortcut.update(userId: recipientId)
	}

	// MARK: - User actions
	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func actionTitle() {

		let profileView = ProfileView(userId: recipientId, chat: false)
		navigationController?.pushViewController(profileView, animated: true)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func actionAttachMessage() {

		dismissKeyboard()

		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

		let alertCamera = UIAlertAction(title: "Camera", style: .default) { action in
			ImagePicker.cameraMulti(target: self, edit: true)
		}
		let alertPhoto = UIAlertAction(title: "Photo", style: .default) { action in
			ImagePicker.photoLibrary(target: self, edit: true)
		}
		let alertVideo = UIAlertAction(title: "Video", style: .default) { action in
			ImagePicker.videoLibrary(target: self, edit: true)
		}
		let alertAudio = UIAlertAction(title: "Audio", style: .default) { action in
			self.actionAudio()
		}
		let alertStickers = UIAlertAction(title: "Sticker", style: .default) { action in
			self.actionStickers()
		}
		let alertLocation = UIAlertAction(title: "Location", style: .default) { action in
			self.actionLocation()
		}

		let configuration	= UIImage.SymbolConfiguration(pointSize: 25, weight: .regular)
		let imageCamera		= UIImage(systemName: "camera", withConfiguration: configuration)
		let imagePhoto		= UIImage(systemName: "photo", withConfiguration: configuration)
		let imageVideo		= UIImage(systemName: "play.rectangle", withConfiguration: configuration)
		let imageAudio		= UIImage(systemName: "music.mic", withConfiguration: configuration)
		let imageStickers	= UIImage(systemName: "tortoise", withConfiguration: configuration)
		let imageLocation	= UIImage(systemName: "location", withConfiguration: configuration)

		alertCamera.setValue(imageCamera, forKey: "image"); 	alert.addAction(alertCamera)
		alertPhoto.setValue(imagePhoto, forKey: "image");		alert.addAction(alertPhoto)
		alertVideo.setValue(imageVideo, forKey: "image");		alert.addAction(alertVideo)
		alertAudio.setValue(imageAudio, forKey: "image");		alert.addAction(alertAudio)
		alertStickers.setValue(imageStickers, forKey: "image");	alert.addAction(alertStickers)
		alertLocation.setValue(imageLocation, forKey: "image");	alert.addAction(alertLocation)

		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

		present(alert, animated: true)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func actionSendMessage(_ text: String) {

		messageSend(text: text, photo: nil, video: nil, audio: nil)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionAudio() {

		let audioView = AudioView()
		audioView.delegate = self
		let navController = NavigationController(rootViewController: audioView)
		navController.isModalInPresentation = true
		navController.modalPresentationStyle = .fullScreen
		present(navController, animated: true)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionStickers() {

		let stickersView = StickersView()
		stickersView.delegate = self
		let navController = NavigationController(rootViewController: stickersView)
		present(navController, animated: true)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionLocation() {

		messageSend(text: nil, photo: nil, video: nil, audio: nil)
	}

	// MARK: - User actions (load earlier)
	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func actionLoadEarlier() {

		messageToDisplay += 12
		refreshLoadEarlier()
		refreshTableView()
	}

	// MARK: - User actions (bubble tap)
	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func actionTapBubble(_ indexPath: IndexPath) {

		let rcmessage = rcmessageAt(indexPath)

		if (rcmessage.mediaStatus == MEDIASTATUS_MANUAL) {
			if (rcmessage.type == MESSAGE_PHOTO) { RCPhotoLoader.manual(rcmessage, in: tableView) }
			if (rcmessage.type == MESSAGE_VIDEO) { RCVideoLoader.manual(rcmessage, in: tableView) }
			if (rcmessage.type == MESSAGE_AUDIO) { RCAudioLoader.manual(rcmessage, in: tableView) }
		}

		if (rcmessage.mediaStatus == MEDIASTATUS_SUCCEED) {
			if (rcmessage.type == MESSAGE_PHOTO) {
				let pictureView = PictureView(chatId: chatId, messageId: rcmessage.messageId)
				present(pictureView, animated: true)
			}
			if (rcmessage.type == MESSAGE_VIDEO) {
				let url = URL(fileURLWithPath: rcmessage.videoPath)
				let videoView = VideoView(url: url)
				present(videoView, animated: true)
			}
			if (rcmessage.type == MESSAGE_AUDIO) {
				if (rcmessage.audioStatus == AUDIOSTATUS_STOPPED) {
					if let sound = Sound(contentsOfFile: rcmessage.audioPath) {
						sound.completionHandler = { didFinish in
							rcmessage.audioStatus = AUDIOSTATUS_STOPPED
							self.refreshTableView()
						}
						SoundManager.shared().playSound(sound)
						rcmessage.audioStatus = AUDIOSTATUS_PLAYING
						refreshTableView()
					}
				} else if (rcmessage.audioStatus == AUDIOSTATUS_PLAYING) {
					SoundManager.shared().stopAllSounds(false)
					rcmessage.audioStatus = AUDIOSTATUS_STOPPED
					refreshTableView()
				}
			}
			if (rcmessage.type == MESSAGE_LOCATION) {
				let mapView = MapView(latitude: rcmessage.latitude, longitude: rcmessage.longitude)
				let navController = NavigationController(rootViewController: mapView)
				present(navController, animated: true)
			}
		}
	}

	// MARK: - User actions (avatar tap)
	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func actionTapAvatar(_ indexPath: IndexPath) {

		let rcmessage = rcmessageAt(indexPath)

		if (rcmessage.userId != AuthUser.userId()) {
			let profileView = ProfileView(userId: rcmessage.userId, chat: false)
			navigationController?.pushViewController(profileView, animated: true)
		}
	}

	// MARK: - User actions (menu)
	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc func actionMenuCopy(_ sender: Any?) {

		if let indexPath = RCMenuItem.indexPath(sender as! UIMenuController) {
			let rcmessage = rcmessageAt(indexPath)
			UIPasteboard.general.string = rcmessage.text
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc func actionMenuSave(_ sender: Any?) {

		if let indexPath = RCMenuItem.indexPath(sender as! UIMenuController) {
			let rcmessage = rcmessageAt(indexPath)

			if (rcmessage.type == MESSAGE_PHOTO) {
				if (rcmessage.mediaStatus == MEDIASTATUS_SUCCEED) {
					if let image = rcmessage.photoImage {
						UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
					}
				}
			}

			if (rcmessage.type == MESSAGE_VIDEO) {
				if (rcmessage.mediaStatus == MEDIASTATUS_SUCCEED) {
					UISaveVideoAtPathToSavedPhotosAlbum(rcmessage.videoPath, self, #selector(video(_:didFinishSavingWithError:contextInfo:)), nil)
				}
			}

			if (rcmessage.type == MESSAGE_AUDIO) {
				if (rcmessage.mediaStatus == MEDIASTATUS_SUCCEED) {
					let path = File.temp(ext: "mp4")
					File.copy(src: rcmessage.audioPath, dest: path, overwrite: true)
					UISaveVideoAtPathToSavedPhotosAlbum(path, self, #selector(video(_:didFinishSavingWithError:contextInfo:)), nil)
				}
			}
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc func actionMenuDelete(_ sender: Any?) {

		if let indexPath = RCMenuItem.indexPath(sender as! UIMenuController) {
			let message = messageAt(indexPath)
			message.update(isDeleted: true)
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc func actionMenuForward(_ sender: Any?) {

		if let indexPath = RCMenuItem.indexPath(sender as! UIMenuController) {
			indexForward = indexPath

			let selectUsersView = SelectUsersView()
			selectUsersView.delegate = self
			let navController = NavigationController(rootViewController: selectUsersView)
			present(navController, animated: true)
		}
	}

	// MARK: - UISaveVideoAtPathToSavedPhotosAlbum
	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeMutableRawPointer?) {

		if (error != nil) { ProgressHUD.showError("Saving failed.") } else { ProgressHUD.showSuccess("Successfully saved.") }
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc func video(_ videoPath: String, didFinishSavingWithError error: NSError?, contextInfo: UnsafeMutableRawPointer?) {

		if (error != nil) { ProgressHUD.showError("Saving failed.") } else { ProgressHUD.showSuccess("Successfully saved.") }
	}

	// MARK: - Table view data source
	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func numberOfSections(in tableView: UITableView) -> Int {

		return messageLoadedCount()
	}

	// MARK: - Cleanup methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionCleanup() {

		tokenDetails?.invalidate()
		tokenMessages?.invalidate()

		detail?.update(typing: false)
	}
}

// MARK: - UIImagePickerControllerDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension RCPrivateChatView: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {

		let video = info[.mediaURL] as? URL
		let photo = info[.editedImage] as? UIImage

		messageSend(text: nil, photo: photo, video: video, audio: nil)

		picker.dismiss(animated: true)
	}
}

// MARK: - AudioDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension RCPrivateChatView: AudioDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func didRecordAudio(path: String) {

		messageSend(text: nil, photo: nil, video: nil, audio: path)
	}
}

// MARK: - StickersDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension RCPrivateChatView: StickersDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func didSelectSticker(sticker: UIImage) {

		messageSend(text: nil, photo: sticker, video: nil, audio: nil)
	}
}

// MARK: - SelectUsersDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension RCPrivateChatView: SelectUsersDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func didSelectUsers(userIds: [String]) {

		if let indexPath = indexForward {
			let message = messageAt(indexPath)

			for userId in userIds {
				let chatId = Singles.create(userId)
				Messages.forward(chatId: chatId, message: message)
			}

			indexForward = nil
		}
	}
}
