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

//-------------------------------------------------------------------------------------------------------------------------------------------------
class ProfileView: UIViewController {

	@IBOutlet var tableView: UITableView!
	@IBOutlet var viewHeader: UIView!
	@IBOutlet var imageUser: UIImageView!
	@IBOutlet var labelInitials: UILabel!
	@IBOutlet var labelName: UILabel!
	@IBOutlet var labelDetails: UILabel!
	@IBOutlet var cellStatus: UITableViewCell!
	@IBOutlet var cellCountry: UITableViewCell!
	@IBOutlet var cellLocation: UITableViewCell!
	@IBOutlet var cellPhone: UITableViewCell!
	@IBOutlet var buttonCallPhone: UIButton!
	@IBOutlet var cellMedia: UITableViewCell!
	@IBOutlet var cellChat: UITableViewCell!
	@IBOutlet var cellFriend: UITableViewCell!
	@IBOutlet var cellBlock: UITableViewCell!

	private var userId = ""
	private var isChatEnabled = false

	private var person: Person!

	//---------------------------------------------------------------------------------------------------------------------------------------------
	init(userId: String, chat: Bool) {

		super.init(nibName: nil, bundle: nil)

		self.userId = userId
		isChatEnabled = chat
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	required init?(coder aDecoder: NSCoder) {

		super.init(coder: aDecoder)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func viewDidLoad() {

		super.viewDidLoad()
		title = "Profile"

		navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)

		tableView.tableHeaderView = viewHeader

		loadPerson()
	}

	// MARK: - Realm methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc func loadPerson() {

		person = realm.object(ofType: Person.self, forPrimaryKey: userId)

		labelInitials.text = person.initials()
		MediaDownload.startUser(person.objectId, pictureAt: person.pictureAt) { image, error in
			if (error == nil) {
				self.imageUser.image = image?.square(to: 70)
				self.labelInitials.text = nil
			}
		}

		labelName.text = person.fullname
		labelDetails.text = person.lastActiveText()

		cellStatus.detailTextLabel?.text = person.status
		cellCountry.detailTextLabel?.text = person.country
		cellLocation.detailTextLabel?.text = person.location

		buttonCallPhone.setTitle(person.phone, for: .normal)

		cellFriend.textLabel?.text = Friends.isFriend(userId) ? "Remove Friend" : "Add Friend"
		cellBlock.textLabel?.text = Blockeds.isBlocked(userId) ? "Unblock User" : "Block User"

		tableView.reloadData()
	}

	// MARK: - User actions
	//---------------------------------------------------------------------------------------------------------------------------------------------
	@IBAction func actionPhoto(_ sender: Any) {

		if let path = MediaDownload.pathUser(person.objectId) {
			if let image = UIImage.image(path, size: 320) {
				let pictureView = PictureView(image: image)
				present(pictureView, animated: true)
			}
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	@IBAction func actionCallPhone(_ sender: Any) {

		let number1 = "tel://\(person.phone)"
		let number2 = number1.replacingOccurrences(of: " ", with: "")

		if let url = URL(string: number2) {
			UIApplication.shared.open(url, options: [:], completionHandler: nil)
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	@IBAction func actionCallAudio(_ sender: Any) {

		let callAudioView = CallAudioView(userId: person.objectId)
		present(callAudioView, animated: true)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	@IBAction func actionCallVideo(_ sender: Any) {

		let callVideoView = CallVideoView(userId: person.objectId)
		present(callVideoView, animated: true)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionAllMedia() {

		let chatId = Singles.chatId(person.objectId)
		let allMediaView = AllMediaView(chatId: chatId)
		navigationController?.pushViewController(allMediaView, animated: true)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionChatPrivate() {

		let chatId = Singles.create(person.objectId)

		let privateChatView = RCPrivateChatView(chatId: chatId, recipientId: person.objectId)
		navigationController?.pushViewController(privateChatView, animated: true)
	}

	// MARK: - User actions (Friend/Unfriend)
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionFriendOrUnfriend() {

		Friends.isFriend(userId) ? actionUnfriend() : actionFriend()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionFriend() {

		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

		alert.addAction(UIAlertAction(title: "Add Friend", style: .default) { action in
			self.actionFriendUser()
		})
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

		present(alert, animated: true)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionFriendUser() {

		Friends.create(userId)
		cellFriend.textLabel?.text = "Remove Friend"
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionUnfriend() {

		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

		alert.addAction(UIAlertAction(title: "Remove Friend", style: .default) { action in
			self.actionUnfriendUser()
		})
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

		present(alert, animated: true)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionUnfriendUser() {

		Friends.update(userId, isDeleted: true)
		cellFriend.textLabel?.text = "Add Friend"
	}

	// MARK: - User actions (Block/Unblock)
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionBlockOrUnblock() {

		Blockeds.isBlocked(userId) ? actionUnblock() : actionBlock()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionBlock() {

		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

		alert.addAction(UIAlertAction(title: "Block User", style: .destructive) { action in
			self.actionBlockUser()
		})
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

		present(alert, animated: true)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionBlockUser() {

		Blockeds.create(userId)
		cellBlock.textLabel?.text = "Unblock User"
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionUnblock() {

		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

		alert.addAction(UIAlertAction(title: "Unblock User", style: .destructive) { action in
			self.actionUnblockUser()
		})
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

		present(alert, animated: true)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionUnblockUser() {

		Blockeds.update(userId, isDeleted: true)
		cellBlock.textLabel?.text = "Block User"
	}
}

// MARK: - UITableViewDataSource
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension ProfileView: UITableViewDataSource {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func numberOfSections(in tableView: UITableView) -> Int {

		return 3
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

		let isBlocker = Blockeds.isBlocker(userId)

		if (section == 0) { return isBlocker ? 3 : 4		}
		if (section == 1) { return isChatEnabled ? 2 : 1	}
		if (section == 2) { return 2						}

		return 0
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

		if (indexPath.section == 0) && (indexPath.row == 0) { return cellStatus			}
		if (indexPath.section == 0) && (indexPath.row == 1) { return cellCountry		}
		if (indexPath.section == 0) && (indexPath.row == 2) { return cellLocation		}
		if (indexPath.section == 0) && (indexPath.row == 3) { return cellPhone			}
		if (indexPath.section == 1) && (indexPath.row == 0) { return cellMedia			}
		if (indexPath.section == 1) && (indexPath.row == 1) { return cellChat			}
		if (indexPath.section == 2) && (indexPath.row == 0) { return cellFriend			}
		if (indexPath.section == 2) && (indexPath.row == 1) { return cellBlock			}

		return UITableViewCell()
	}
}

// MARK: - UITableViewDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension ProfileView: UITableViewDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

		tableView.deselectRow(at: indexPath, animated: true)

		if (indexPath.section == 1) && (indexPath.row == 0) { actionAllMedia()			}
		if (indexPath.section == 1) && (indexPath.row == 1) { actionChatPrivate()		}
		if (indexPath.section == 2) && (indexPath.row == 0) { actionFriendOrUnfriend()	}
		if (indexPath.section == 2) && (indexPath.row == 1) { actionBlockOrUnblock()	}
	}
}
