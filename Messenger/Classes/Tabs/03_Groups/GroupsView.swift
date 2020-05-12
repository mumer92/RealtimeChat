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
import RealmSwift

//-------------------------------------------------------------------------------------------------------------------------------------------------
class GroupsView: UIViewController {

	@IBOutlet var searchBar: UISearchBar!
	@IBOutlet var tableView: UITableView!

	private var tokenMembers1: NotificationToken? = nil
	private var tokenMembers2: NotificationToken? = nil
	private var tokenGroups: NotificationToken? = nil

	private var members1 = realm.objects(Member.self).filter(falsepredicate)
	private var members2 = realm.objects(Member.self).filter(falsepredicate)
	private var groups = realm.objects(Group.self).filter(falsepredicate)

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {

		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

		tabBarItem.image = UIImage(systemName: "person.2")
		tabBarItem.title = "Groups"

		NotificationCenter.addObserver(target: self, selector: #selector(loadMembers1), name: NOTIFICATION_USER_LOGGED_IN)
		NotificationCenter.addObserver(target: self, selector: #selector(actionCleanup), name: NOTIFICATION_USER_LOGGED_OUT)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	required init?(coder aDecoder: NSCoder) {

		super.init(coder: aDecoder)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func viewDidLoad() {

		super.viewDidLoad()
		title = "Groups"

		navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(actionNew))

		tableView.register(UINib(nibName: "GroupsCell", bundle: nil), forCellReuseIdentifier: "GroupsCell")

		tableView.tableFooterView = UIView()

		if (AuthUser.userId() != "") {
			loadMembers1()
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func viewDidAppear(_ animated: Bool) {

		super.viewDidAppear(animated)

		if (AuthUser.userId() != "") {
			if (Persons.fullname() != "") {

			} else { Users.onboard(target: self) }
		} else { Users.login(target: self) }
	}

	// MARK: - Realm methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc func loadMembers1() {

		let predicate = NSPredicate(format: "userId == %@ AND isActive == YES", AuthUser.userId())
		members1 = realm.objects(Member.self).filter(predicate)

		tokenMembers1?.invalidate()
		members1.safeObserve({ changes in
			self.loadMembers2()
			self.loadGroups()
		}, completion: { token in
			self.tokenMembers1 = token
		})
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func loadMembers2() {

		let predicate = NSPredicate(format: "chatId IN %@ AND isActive == YES", Members.chatIds())
		members2 = realm.objects(Member.self).filter(predicate)

		tokenMembers2?.invalidate()
		members2.safeObserve({ changes in
			self.refreshTableView()
		}, completion: { token in
			self.tokenMembers2 = token
		})
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func loadGroups(text: String = "") {

		let predicate1 = NSPredicate(format: "objectId IN %@ AND isDeleted == NO", Members.chatIds())
		let predicate2 = (text != "") ? NSPredicate(format: "name CONTAINS[c] %@", text) : NSPredicate(value: true)

		groups = realm.objects(Group.self).filter(predicate1).filter(predicate2).sorted(byKeyPath: "name")

		tokenGroups?.invalidate()
		groups.safeObserve({ changes in
			self.refreshTableView()
		}, completion: { token in
			self.tokenGroups = token
		})
	}

	// MARK: - Refresh methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func refreshTableView() {

		tableView.reloadData()
	}

	// MARK: - User actions
	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc func actionNew() {

		let groupCreateView = GroupCreateView()
		let navController = NavigationController(rootViewController: groupCreateView)
		present(navController, animated: true)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionNewGroup() {

		if (tabBarController?.tabBar.isHidden ?? true) { return }

		tabBarController?.selectedIndex = 2

		actionNew()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionChatGroup(chatId: String) {

		let groupChatView = RCGroupChatView(chatId: chatId)
		groupChatView.hidesBottomBarWhenPushed = true
		navigationController?.pushViewController(groupChatView, animated: true)
	}

	// MARK: - Cleanup methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc func actionCleanup() {

		tokenMembers1?.invalidate()
		tokenMembers2?.invalidate()
		tokenGroups?.invalidate()

		members1 = realm.objects(Member.self).filter(falsepredicate)
		members2 = realm.objects(Member.self).filter(falsepredicate)
		groups = realm.objects(Group.self).filter(falsepredicate)

		refreshTableView()
	}
}

// MARK: - UIScrollViewDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension GroupsView: UIScrollViewDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {

		view.endEditing(true)
	}
}

// MARK: - UITableViewDataSource
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension GroupsView: UITableViewDataSource {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func numberOfSections(in tableView: UITableView) -> Int {

		return 1
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

		return groups.count
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

		let cell = tableView.dequeueReusableCell(withIdentifier: "GroupsCell", for: indexPath) as! GroupsCell

		let group = groups[indexPath.row]
		cell.bindData(group: group)

		return cell
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {

		let group = groups[indexPath.row]
		return (group.ownerId == AuthUser.userId())
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {

		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

		alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { action in
			let group = self.groups[indexPath.row]
			group.update(isDeleted: true)
		})
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

		present(alert, animated: true)
	}
}

// MARK: - UITableViewDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension GroupsView: UITableViewDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

		tableView.deselectRow(at: indexPath, animated: true)

		let group = groups[indexPath.row]
		actionChatGroup(chatId: group.chatId)
	}
}

// MARK: - UISearchBarDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension GroupsView: UISearchBarDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

		loadGroups(text: searchText)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func searchBarTextDidBeginEditing(_ searchBar_: UISearchBar) {

		searchBar.setShowsCancelButton(true, animated: true)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func searchBarTextDidEndEditing(_ searchBar_: UISearchBar) {

		searchBar.setShowsCancelButton(false, animated: true)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func searchBarCancelButtonClicked(_ searchBar_: UISearchBar) {

		searchBar.text = ""
		searchBar.resignFirstResponder()
		loadGroups()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func searchBarSearchButtonClicked(_ searchBar_: UISearchBar) {

		searchBar.resignFirstResponder()
	}
}
