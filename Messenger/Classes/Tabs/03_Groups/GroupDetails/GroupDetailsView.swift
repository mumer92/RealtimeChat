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

//-------------------------------------------------------------------------------------------------------------------------------------------------
class GroupDetailsView: UIViewController {

	@IBOutlet var tableView: UITableView!
	@IBOutlet var cellDetails: UITableViewCell!
	@IBOutlet var labelName: UILabel!
	@IBOutlet var cellMedia: UITableViewCell!
	@IBOutlet var cellLeave: UITableViewCell!
	@IBOutlet var viewFooter: UIView!
	@IBOutlet var labelFooter1: UILabel!
	@IBOutlet var labelFooter2: UILabel!

	private var chatId = ""
	private var group: Group!

	private var tokenMembers: NotificationToken? = nil
	private var tokenPersons: NotificationToken? = nil

	private var members = realm.objects(Member.self).filter(falsepredicate)
	private var persons = realm.objects(Person.self).filter(falsepredicate)

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
		title = "Group"

		navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
		navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: self, action: #selector(actionMore))

		tableView.tableFooterView = viewFooter

		loadGroup()
		loadMembers()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func viewWillDisappear(_ animated: Bool) {

		super.viewWillDisappear(animated)

		if (isMovingFromParent) {
			actionCleanup()
		}
	}

	// MARK: - Realm methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func loadGroup() {

		group = realm.object(ofType: Group.self, forPrimaryKey: chatId)

		labelName.text = group.name

		if let person = realm.object(ofType: Person.self, forPrimaryKey: group.ownerId) {
			labelFooter1.text = "Created by \(person.fullname)"
			labelFooter2.text = Convert.timestampToMediumTime(group.createdAt)
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func loadMembers() {

		let predicate = NSPredicate(format: "chatId == %@ AND isActive == YES", chatId)
		members = realm.objects(Member.self).filter(predicate)

		tokenMembers?.invalidate()
		members.safeObserve({ changes in
			self.loadPersons()
		}, completion: { token in
			self.tokenMembers = token
		})
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func loadPersons() {

		let predicate = NSPredicate(format: "objectId IN %@", Members.userIds(chatId: chatId))
		persons = realm.objects(Person.self).filter(predicate).sorted(byKeyPath: "fullname")

		tokenPersons?.invalidate()
		persons.safeObserve({ changes in
			self.refreshTableView()
		}, completion: { token in
			self.tokenPersons = token
		})
	}

	// MARK: - Refresh methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func refreshTableView() {

		tableView.reloadData()
	}

	// MARK: - User actions
	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc func actionMore() {

		if isGroupOwner() { actionMoreOwner() } else { actionMoreMember() }
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionMoreOwner() {

		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

		alert.addAction(UIAlertAction(title: "Add Members", style: .default) { action in
			self.actionAddMembers()
		})
		alert.addAction(UIAlertAction(title: "Rename Group", style: .default) { action in
			self.actionRenameGroup()
		})
		alert.addAction(UIAlertAction(title: "Delete Group", style: .destructive) { action in
			self.group.update(isDeleted: true)
			NotificationCenter.post(notification: NOTIFICATION_CLEANUP_CHATVIEW)
			self.navigationController?.popToRootViewController(animated: true)
		})
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

		present(alert, animated: true)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionMoreMember() {

		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

		alert.addAction(UIAlertAction(title: "Leave Group", style: .destructive) { action in
			Members.update(chatId: self.chatId, userId: AuthUser.userId(), isActive: false)
			NotificationCenter.post(notification: NOTIFICATION_CLEANUP_CHATVIEW)
			self.navigationController?.popToRootViewController(animated: true)
		})
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

		present(alert, animated: true)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionAddMembers() {

		let selectUsersView = SelectUsersView()
		selectUsersView.delegate = self
		let navController = NavigationController(rootViewController: selectUsersView)
		present(navController, animated: true)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionRenameGroup() {

		let alert = UIAlertController(title: "Rename Group", message: "Enter a new name for this Group", preferredStyle: .alert)

		alert.addTextField(configurationHandler: { textField in
			textField.text = self.group.name
			textField.placeholder = "Group name"
		})

		alert.addAction(UIAlertAction(title: "Save", style: .default) { action in
			let textField = alert.textFields![0]
			if let text = textField.text {
				if (text.count != 0) {
					self.group.update(name: text)
					self.labelName.text = text
				} else {
					ProgressHUD.showError("Group name must be specified.")
				}
			}
		})

		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

		present(alert, animated: true)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionAllMedia() {

		let allMediaView = AllMediaView(chatId: chatId)
		navigationController?.pushViewController(allMediaView, animated: true)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionProfile(userId: String) {

		let profileView = ProfileView(userId: userId, chat: true)
		navigationController?.pushViewController(profileView, animated: true)
	}

	// MARK: - Cleanup methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionCleanup() {

		tokenMembers?.invalidate()
		tokenPersons?.invalidate()
	}

	// MARK: - Helper methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func titleForHeaderMembers() -> String? {

		let text = (persons.count > 1) ? "MEMBERS" : "MEMBER"
		return "\(persons.count) \(text)"
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func isGroupOwner() -> Bool {

		if let group = self.group {
			return (group.ownerId == AuthUser.userId())
		}
		return false
	}
}

// MARK: - SelectUsersDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension GroupDetailsView: SelectUsersDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func didSelectUsers(userIds: [String]) {

		Details.update(chatId: chatId, userIds: userIds)
		Members.update(chatId: chatId, userIds: userIds)
	}
}

// MARK: - UITableViewDataSource
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension GroupDetailsView: UITableViewDataSource {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func numberOfSections(in tableView: UITableView) -> Int {

		return 4
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

		if (section == 0) { return 1 						}
		if (section == 1) { return 1 						}
		if (section == 2) { return persons.count			}
		if (section == 3) {	return isGroupOwner() ? 0 : 1	}

		return 0
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

		if (section == 0) { return nil						}
		if (section == 1) { return nil						}
		if (section == 2) { return titleForHeaderMembers()	}
		if (section == 3) { return nil 						}

		return nil
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

		if (indexPath.section == 0) && (indexPath.row == 0) {
			return cellDetails
		}

		if (indexPath.section == 1) && (indexPath.row == 0) {
			return cellMedia
		}

		if (indexPath.section == 2) {
			var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "cell")
			if (cell == nil) { cell = UITableViewCell(style: .default, reuseIdentifier: "cell") }

			let person = persons[indexPath.row]
			cell.textLabel?.text = person.fullname

			return cell
		}

		if (indexPath.section == 3) && (indexPath.row == 0) {
			return cellLeave
		}

		return UITableViewCell()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {

		if (indexPath.section == 2) {
			if (isGroupOwner()) {
				let person = persons[indexPath.row]
				return (person.objectId != AuthUser.userId())
			}
		}

		return false
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {

		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

		alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { action in
			let person = self.persons[indexPath.row]
			Members.update(chatId: self.chatId, userId: person.objectId, isActive: false)
		})
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

		present(alert, animated: true)
	}
}

// MARK: - UITableViewDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension GroupDetailsView: UITableViewDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

		tableView.deselectRow(at: indexPath, animated: true)

		if (indexPath.section == 1) && (indexPath.row == 0) {
			actionAllMedia()
		}

		if (indexPath.section == 2) {
			let person = persons[indexPath.row]
			if (person.objectId == AuthUser.userId()) {
				ProgressHUD.showSuccess("This is you.")
			} else {
				actionProfile(userId: person.objectId)
			}
		}

		if (indexPath.section == 3) && (indexPath.row == 0) {
			actionMoreMember()
		}
	}
}
