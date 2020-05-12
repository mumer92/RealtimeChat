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

import MapKit
import MessageKit
import InputBarAccessoryView
import RealmSwift

//-------------------------------------------------------------------------------------------------------------------------------------------------
class MKGroupChatView: MessagesViewController {

	private var chatId = ""

	private var detail: Detail?
	private var details = realm.objects(Detail.self).filter(falsepredicate)
	private var messages = realm.objects(Message.self).filter(falsepredicate)

	private var tokenDetails: NotificationToken? = nil
	private var tokenMessages: NotificationToken? = nil

	private var mkmessages: [String: MKMessage] = [:]
	private var avatarImages: [String: UIImage] = [:]

	private var messageToDisplay: Int = 12

	private var typingCounter: Int = 0
	private var lastRead: Int64 = 0

	let currentUser = MKSender(senderId: AuthUser.userId(), displayName: Persons.fullname())

	open lazy var audioController = MKAudioController(messageCollectionView: messagesCollectionView)

	let refreshControl = UIRefreshControl()

	//---------------------------------------------------------------------------------------------------------------------------------------------
	init(chatId: String) {

		super.init(nibName: nil, bundle: nil)

		self.chatId = chatId
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	required init?(coder aDecoder: NSCoder) {

		super.init(coder: aDecoder)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func viewDidLoad() {

		super.viewDidLoad()

		NotificationCenter.addObserver(target: self, selector: #selector(actionCleanup), name: NOTIFICATION_CLEANUP_CHATVIEW)

		configureMessageCollectionView()
		configureMessageInputBar()

		loadDetail()
		loadDetails()
		loadMessages()

		let menuItemForward = UIMenuItem(title: "Forward", action: #selector(MessageCollectionViewCell.forward(_:)))
		UIMenuController.shared.menuItems = [menuItemForward]

		DispatchQueue.main.async {
			self.messagesCollectionView.reloadData()
			self.messagesCollectionView.scrollToBottom()
		}
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

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override var preferredStatusBarStyle: UIStatusBarStyle {

		return .lightContent
	}

	// MARK: - Configure methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func configureMessageCollectionView() {

		messagesCollectionView.messagesDataSource = self
		messagesCollectionView.messageCellDelegate = self
		messagesCollectionView.messagesDisplayDelegate = self
		messagesCollectionView.messagesLayoutDelegate = self

		scrollsToBottomOnKeyboardBeginsEditing = true
		maintainPositionOnKeyboardFrameChanged = true

		messagesCollectionView.refreshControl = refreshControl
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func configureMessageInputBar() {

		messageInputBar.delegate = self

		let button = InputBarButtonItem()
		button.image = UIImage(named: "mkchat_attach")
		button.setSize(CGSize(width: 36, height: 36), animated: false)

		button.onKeyboardSwipeGesture { item, gesture in
			if (gesture.direction == .left)	 { item.inputBarAccessoryView?.setLeftStackViewWidthConstant(to: 0, animated: true)		}
			if (gesture.direction == .right) { item.inputBarAccessoryView?.setLeftStackViewWidthConstant(to: 36, animated: true)	}
		}

		button.onTouchUpInside { item in
			self.actionAttachMessage()
		}

		messageInputBar.setStackViewItems([button], forStack: .left, animated: false)

		messageInputBar.sendButton.title = nil
		messageInputBar.sendButton.image = UIImage(named: "mkchat_send")
		messageInputBar.sendButton.setSize(CGSize(width: 36, height: 36), animated: false)

		messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
		messageInputBar.setRightStackViewWidthConstant(to: 36, animated: false)

		messageInputBar.inputTextView.isImagePasteEnabled = false
		messageInputBar.backgroundView.backgroundColor = .systemBackground
		messageInputBar.inputTextView.backgroundColor = .systemBackground
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
					self.refreshCollectionView()
					self.scrollToBottom()
				case .update(_, let delete, let insert, _):
					self.messageToDisplay -= delete.count
					self.messageToDisplay += insert.count
					self.refreshCollectionView()
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
	func mkmessageAt(_ indexPath: IndexPath) -> MKMessage {

		let message = messageAt(indexPath)

		if let mkmessage = mkmessages[message.objectId] {
			mkmessage.update(message)
			loadMedia(mkmessage)
			return mkmessage
		}

		let mkmessage = MKMessage(message: message)
		mkmessages[message.objectId] = mkmessage
		loadMedia(mkmessage)
		return mkmessage
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func loadMedia(_ mkmessage: MKMessage) {

		if (mkmessage.mediaStatus != MEDIASTATUS_UNKNOWN) { return }
		if (mkmessage.incoming) && (mkmessage.isMediaQueued) { return }
		if (mkmessage.incoming) && (mkmessage.isMediaFailed) { return }

		switch mkmessage.type {
			case MESSAGE_PHOTO: MKPhotoLoader.start(mkmessage, in: messagesCollectionView)
			case MESSAGE_VIDEO: MKVideoLoader.start(mkmessage, in: messagesCollectionView)
			case MESSAGE_AUDIO: MKAudioLoader.start(mkmessage, in: messagesCollectionView)
			default: break
		}
	}

	// MARK: - Typing indicator methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func typingIndicatorUpdate() {

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

		if let group = realm.object(ofType: Group.self, forPrimaryKey: chatId) {
			title = group.name
		}
	}

	// MARK: - Refresh methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func refreshCollectionView() {

		messagesCollectionView.reloadData()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func scrollToBottom() {

		DispatchQueue.main.async(after: 0.1) {
			self.scrollToBottomIfVisible()
		}
		detail?.update(lastRead: Date().timestamp())
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func scrollToBottomIfVisible() {

		if (messageLoadedCount() != 0) {
			let indexPath = IndexPath(item: 0, section: Int(messageLoadedCount()-1))
			if (messagesCollectionView.indexPathsForVisibleItems.contains(indexPath)) {
				self.messagesCollectionView.scrollToBottom(animated: true)
			}
		}
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

		setTypingIndicatorViewHidden((typing == false), animated: false, whilePerforming: nil) { [weak self] success in
			if (success) { self?.scrollToBottomIfVisible() }
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func refreshLastRead() {

		for detail in details {
			if (detail.lastRead > lastRead) {
				lastRead = detail.lastRead
			}
		}
		refreshCollectionView()
	}

	// MARK: - Message send methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func messageSend(text: String?, photo: UIImage?, video: URL?, audio: String?) {

		Messages.send(chatId: chatId, text: text, photo: photo, video: video, audio: audio)
	}

	// MARK: - User actions
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionAttachMessage() {

		messageInputBar.inputTextView.resignFirstResponder()

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

	// MARK: - User actions (menu)
	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func actionMenuDelete(at indexPath: IndexPath) {

		let message = messageAt(indexPath)
		message.update(isDeleted: true)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func actionMenuForward(at indexPath: IndexPath) {

	}

	// MARK: - Cleanup methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc func actionCleanup() {

		audioController.stopAnyOngoingPlaying()

		tokenDetails?.invalidate()
		tokenMessages?.invalidate()

		details = realm.objects(Detail.self).filter(falsepredicate)
		messages = realm.objects(Message.self).filter(falsepredicate)

		refreshCollectionView()

		detail?.update(typing: false)

		NotificationCenter.removeObserver(target: self)
	}

	// MARK: - UIScrollViewDelegate
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {

		if (refreshControl.isRefreshing) {
			if (messageToDisplay < messageTotalCount()) {
				messageToDisplay += 12
				messagesCollectionView.reloadDataAndKeepOffset()
			}
			refreshControl.endRefreshing()
		}
	}

	// MARK: - Menu controller methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {

		if (isSectionReservedForTypingIndicator(indexPath.section)) { return false }

		selectedIndexPathForMenu = indexPath

		return true
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {

		if (isSectionReservedForTypingIndicator(indexPath.section)) { return false }

		if (action == NSSelectorFromString("delete:"))	{ return true }
		if (action == NSSelectorFromString("forward:"))	{ return true }

		return false
	}
}

// MARK: - UIImagePickerControllerDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension MKGroupChatView: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

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
extension MKGroupChatView: AudioDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func didRecordAudio(path: String) {

		messageSend(text: nil, photo: nil, video: nil, audio: path)
	}
}

// MARK: - StickersDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension MKGroupChatView: StickersDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func didSelectSticker(sticker: UIImage) {

		messageSend(text: nil, photo: sticker, video: nil, audio: nil)
	}
}

// MARK: - MessagesDataSource
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension MKGroupChatView: MessagesDataSource {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func currentSender() -> SenderType {

		return currentUser
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {

		return messageLoadedCount()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {

		return mkmessageAt(indexPath)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {

		if (indexPath.section % 3 == 0) {
			let showLoadMore = (indexPath.section == 0) && (messageTotalCount() > messageToDisplay)
			let text = showLoadMore ? "Pull to load more" : MessageKitDateFormatter.shared.string(from: message.sentDate)
			let font = showLoadMore ? UIFont.systemFont(ofSize: 13) : UIFont.boldSystemFont(ofSize: 10)
			let color = showLoadMore ? UIColor.blue : UIColor.darkGray
			return NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color])
		}
		return nil
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func cellBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {

		if (isFromCurrentSender(message: message)) {
			let message = messageAt(indexPath)
			var status = (message.createdAt > lastRead) ? STATUS_SENT : STATUS_READ
			if (message.isMediaFailed)	{ status = STATUS_FAILED }
			if (message.isMediaQueued)	{ status = STATUS_QUEUED }
			if (message.syncRequired)	{ status = STATUS_QUEUED }
			return NSAttributedString(string: status, attributes: [.font: UIFont.boldSystemFont(ofSize: 10), .foregroundColor: UIColor.darkGray])
		}
		return nil
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {

		if (isFromCurrentSender(message: message) == false) {
			let name = message.sender.displayName
			return NSAttributedString(string: name, attributes: [.font: UIFont.boldSystemFont(ofSize: 10), .foregroundColor: UIColor.darkGray])
		}
		return nil
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {

		return nil
	}
}

// MARK: - MessageCellDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension MKGroupChatView: MessageCellDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func didTapAvatar(in cell: MessageCollectionViewCell) {

	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func didTapImage(in cell: MessageCollectionViewCell) {

		if let indexPath = messagesCollectionView.indexPath(for: cell) {
			let mkmessage = mkmessageAt(indexPath)

			if (mkmessage.type == MESSAGE_PHOTO) {
				if (mkmessage.mediaStatus == MEDIASTATUS_MANUAL) {
					MKPhotoLoader.manual(mkmessage, in: messagesCollectionView)
				}
				if (mkmessage.mediaStatus == MEDIASTATUS_SUCCEED) {
					let pictureView = PictureView(chatId: chatId, messageId: mkmessage.messageId)
					present(pictureView, animated: true)
				}
			}

			if (mkmessage.type == MESSAGE_VIDEO) {
				if (mkmessage.mediaStatus == MEDIASTATUS_MANUAL) {
					MKVideoLoader.manual(mkmessage, in: messagesCollectionView)
				}
				if (mkmessage.mediaStatus == MEDIASTATUS_SUCCEED) {
					if let videoItem = mkmessage.videoItem {
						if let url = videoItem.url {
							let videoView = VideoView(url: url)
							present(videoView, animated: true)
						}
					}
				}
			}
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func didTapMessage(in cell: MessageCollectionViewCell) {

		if let indexPath = messagesCollectionView.indexPath(for: cell) {
			let mkmessage = mkmessageAt(indexPath)

			if (mkmessage.type == MESSAGE_AUDIO) {
				if (mkmessage.mediaStatus == MEDIASTATUS_MANUAL) {
					MKAudioLoader.manual(mkmessage, in: messagesCollectionView)
				}
			}

			if (mkmessage.type == MESSAGE_LOCATION) {
				if let locationItem = mkmessage.locationItem {
					let mapView = MapView(location: locationItem.location)
					let navController = NavigationController(rootViewController: mapView)
					present(navController, animated: true)
				}
			}
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func didTapPlayButton(in cell: AudioMessageCell) {

		if let indexPath = messagesCollectionView.indexPath(for: cell) {
			let mkmessage = mkmessageAt(indexPath)
			if (mkmessage.mediaStatus == MEDIASTATUS_SUCCEED) {
				audioController.toggleSound(for: mkmessage, in: cell)
			}
		}
	}
}

// MARK: - MessagesDisplayDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension MKGroupChatView: MessagesDisplayDelegate {

	// MARK: - Text Messages
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {

		return isFromCurrentSender(message: message) ? .white : .darkText
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedString.Key: Any] {

		switch detector {
			case .hashtag, .mention: return [.foregroundColor: UIColor.blue]
			default: return MessageLabel.defaultAttributes
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {

		return [.url, .address, .phoneNumber, .date, .transitInformation, .mention, .hashtag]
	}

	// MARK: - All Messages
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {

		return isFromCurrentSender(message: message) ? MKDefaults.bubbleColorOutgoing : MKDefaults.bubbleColorIncoming
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {

		let tail: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
		return .bubbleTail(tail, .curved)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {

		let mkmessage = mkmessageAt(indexPath)
		var imageAvatar = avatarImages[mkmessage.userId]

		if (imageAvatar == nil) {
			if let path = MediaDownload.pathUser(mkmessage.userId) {
				imageAvatar = UIImage.image(path, size: 30)
				avatarImages[mkmessage.userId] = imageAvatar
			}
		}

		if (imageAvatar == nil) {
			MediaDownload.startUser(mkmessage.userId, pictureAt: mkmessage.userPictureAt) { image, error in
				if (error == nil) {
					self.refreshCollectionView()
				}
			}
		}

		avatarView.set(avatar: Avatar(image: imageAvatar, initials: mkmessage.userInitials))
	}

	// MARK: - Media Messages
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {

		let mkmessage = mkmessageAt(indexPath)
		if let messageContainerView = imageView.superview as? MessageContainerView {
			updateMediaMessageStatus(mkmessage, in: messageContainerView)
		}
	}

	// MARK: - Location Messages
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func annotationViewForLocation(message: MessageType, at indexPath: IndexPath, in messageCollectionView: MessagesCollectionView) -> MKAnnotationView? {

		if let image = UIImage(named: "mkchat_annotation") {
			let annotationView = MKAnnotationView(annotation: nil, reuseIdentifier: nil)
			annotationView.image = image
			annotationView.centerOffset = CGPoint(x: 0, y: -image.size.height / 2)
			return annotationView
		}
		return nil
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func animationBlockForLocation(message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> ((UIImageView) -> Void)? {

		return nil
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func snapshotOptionsForLocation(message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LocationMessageSnapshotOptions {

		let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
		return LocationMessageSnapshotOptions(showsBuildings: true, showsPointsOfInterest: true, span: span)
	}

	// MARK: - Audio Messages
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func audioTintColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {

		return isFromCurrentSender(message: message) ? MKDefaults.audioTextColorOutgoing : MKDefaults.audioTextColorIncoming
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func configureAudioCell(_ cell: AudioMessageCell, message: MessageType) {

		audioController.configureAudioCell(cell, message: message)

		if let mkmessage = mkmessages[message.messageId] {
			updateMediaMessageStatus(mkmessage, in: cell.messageContainerView)
		}
	}

	// MARK: - Helper methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func updateMediaMessageStatus(_ mkmessage: MKMessage, in messageContainerView: MessageContainerView) {

		let color = isFromCurrentSender(message: mkmessage) ? MKDefaults.bubbleColorOutgoing : MKDefaults.bubbleColorIncoming

		if (mkmessage.mediaStatus == MEDIASTATUS_LOADING) {
			messageContainerView.showOverlayView(color)
			messageContainerView.showActivityIndicator()
			messageContainerView.hideManualDownloadIcon()
		}
		if (mkmessage.mediaStatus == MEDIASTATUS_MANUAL) {
			messageContainerView.showOverlayView(color)
			messageContainerView.hideActivityIndicator()
			messageContainerView.showManualDownloadIcon()
		}
		if (mkmessage.mediaStatus == MEDIASTATUS_SUCCEED) {
			messageContainerView.hideOverlayView()
			messageContainerView.hideActivityIndicator()
			messageContainerView.hideManualDownloadIcon()
		}
	}
}

// MARK: - MessagesLayoutDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension MKGroupChatView: MessagesLayoutDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {

		if (indexPath.section % 3 == 0) {
			if ((indexPath.section == 0) && (messageTotalCount() > messageToDisplay)) {
				return 40
			}
			return 18
		}
		return 0
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func cellBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {

		return isFromCurrentSender(message: message) ? 17 : 0
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {

		return isFromCurrentSender(message: message) ? 0 : 17
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {

		return 0
	}
}

// MARK: - InputBarAccessoryViewDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension MKGroupChatView: InputBarAccessoryViewDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func inputBar(_ inputBar: InputBarAccessoryView, textViewTextDidChangeTo text: String) {

		typingIndicatorUpdate()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {

		for component in inputBar.inputTextView.components {
			if let text = component as? String {
				messageSend(text: text, photo: nil, video: nil, audio: nil)
			}
		}
		messageInputBar.inputTextView.text = ""
		messageInputBar.invalidatePlugins()
	}
}
