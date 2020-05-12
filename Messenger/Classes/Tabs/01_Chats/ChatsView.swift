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

//-------------------------------------------------------------------------------------------------------------------------------------------------
class ChatsView: UIViewController {

	@IBOutlet var viewTitle: UIView!
	@IBOutlet var segmentedControl: UISegmentedControl!

	@IBOutlet var searchBar: UISearchBar!
	@IBOutlet var tableView: UITableView!

	private var tokenMembers: NotificationToken? = nil
	private var tokenChats: NotificationToken? = nil

	private var members	= realm.objects(Member.self).filter(falsepredicate)
	private var chats	= realm.objects(Chat.self).filter(falsepredicate)

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {

		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

		tabBarItem.image = UIImage(systemName: "text.bubble")
		tabBarItem.title = "Chats"

		NotificationCenter.addObserver(target: self, selector: #selector(loadMembers), name: NOTIFICATION_USER_LOGGED_IN)
		NotificationCenter.addObserver(target: self, selector: #selector(actionCleanup), name: NOTIFICATION_USER_LOGGED_OUT)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	required init?(coder aDecoder: NSCoder) {

		super.init(coder: aDecoder)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func viewDidLoad() {

		super.viewDidLoad()
		navigationItem.titleView = viewTitle

		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(actionCompose))

		tableView.register(UINib(nibName: "ChatsCell", bundle: nil), forCellReuseIdentifier: "ChatsCell")

		tableView.tableFooterView = UIView()

		if (AuthUser.userId() != "") {
			loadMembers()
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
	@objc func loadMembers() {

		let predicate = NSPredicate(format: "userId == %@ AND isActive == YES", AuthUser.userId())
		members = realm.objects(Member.self).filter(predicate)

		tokenMembers?.invalidate()
		members.safeObserve({ changes in
			self.loadChats()
		}, completion: { token in
			self.tokenMembers = token
		})
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func loadChats(text: String = "") {

		let predicate1 = NSPredicate(format: "objectId IN %@ AND lastMessageAt != 0", Members.chatIds())
		let predicate2 = NSPredicate(format: "isDeleted == NO AND isArchived == NO AND isGroupDeleted == NO")
		let predicate3 = (text != "") ? NSPredicate(format: "details CONTAINS[c] %@", text) : NSPredicate(value: true)

		let predicate = NSCompoundPredicate(type: .and, subpredicates: [predicate1, predicate2, predicate3])
		chats = realm.objects(Chat.self).filter(predicate).sorted(byKeyPath: "lastMessageAt", ascending: false)

		tokenChats?.invalidate()
		chats.safeObserve({ changes in
			self.refreshTableView()
		}, completion: { token in
			self.tokenChats = token
		})
	}

	// MARK: - Refresh methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func refreshTableView() {

		tableView.reloadData()
		self.refreshTabCounter()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func refreshTabCounter() {

		var total: Int = 0

		for chat in chats {
			total += chat.unreadCount
		}

		let item = tabBarController?.tabBar.items?[0]
		item?.badgeValue = (total != 0) ? "\(total)" : nil

		UIApplication.shared.applicationIconBadgeNumber = total
	}

	// MARK: - User actions
	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc func actionCompose() {

		let selectUserView = SelectUserView()
		selectUserView.delegate = self
		let navController = NavigationController(rootViewController: selectUserView)
		present(navController, animated: true)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionNewChat() {

		if (tabBarController?.tabBar.isHidden ?? true) { return }

		tabBarController?.selectedIndex = 0

		actionCompose()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionRecentUser(userId: String) {

		if (tabBarController?.tabBar.isHidden ?? true) { return }

		tabBarController?.selectedIndex = 0

		let chatId = Singles.create(userId)
		actionChatPrivate(chatId: chatId, recipientId: userId)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionChatPrivate(chatId: String, recipientId: String) {

		if (segmentedControl.selectedSegmentIndex == 0) {
			let privateChatView = RCPrivateChatView(chatId: chatId, recipientId: recipientId)
			privateChatView.hidesBottomBarWhenPushed = true
			navigationController?.pushViewController(privateChatView, animated: true)
		}

		if (segmentedControl.selectedSegmentIndex == 1) {
			let privateChatView = MKPrivateChatView(chatId: chatId, recipientId: recipientId)
			privateChatView.hidesBottomBarWhenPushed = true
			navigationController?.pushViewController(privateChatView, animated: true)
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionChatGroup(chatId: String) {

		if (segmentedControl.selectedSegmentIndex == 0) {
			let groupChatView = RCGroupChatView(chatId: chatId)
			groupChatView.hidesBottomBarWhenPushed = true
			navigationController?.pushViewController(groupChatView, animated: true)
		}

		if (segmentedControl.selectedSegmentIndex == 1) {
			let groupChatView = MKGroupChatView(chatId: chatId)
			groupChatView.hidesBottomBarWhenPushed = true
			navigationController?.pushViewController(groupChatView, animated: true)
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionDelete(at indexPath: IndexPath) {

		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

		alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { action in
			let chat = self.chats[indexPath.row]
			Details.update(chatId: chat.objectId, isDeleted: true)
		})
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

		present(alert, animated: true)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionMore(at indexPath: IndexPath) {

		let chat = self.chats[indexPath.row]
		let isMuted = chat.mutedUntil > Date().timestamp()
		let titleMute = isMuted ? "Unmute" : "Mute"

		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

		alert.addAction(UIAlertAction(title: titleMute, style: .default) { action in
			if (isMuted)	{ self.actionUnmute(at: indexPath)	}
			if (!isMuted)	{ self.actionMute(at: indexPath)	}
		})
		alert.addAction(UIAlertAction(title: "Archive", style: .default) { action in
			let chat = self.chats[indexPath.row]
			Details.update(chatId: chat.objectId, isArchived: true)
		})
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

		present(alert, animated: true)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionUnmute(at indexPath: IndexPath) {

		let chat = self.chats[indexPath.row]
		Details.update(chatId: chat.objectId, mutedUntil: 0)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionMute(at indexPath: IndexPath) {

		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

		alert.addAction(UIAlertAction(title: "10 hours", style: .default) { action in
			self.actionMute(at: indexPath, until: 10)
		})
		alert.addAction(UIAlertAction(title: "7 days", style: .default) { action in
			self.actionMute(at: indexPath, until: 168)
		})
		alert.addAction(UIAlertAction(title: "1 month", style: .default) { action in
			self.actionMute(at: indexPath, until: 720)
		})
		alert.addAction(UIAlertAction(title: "1 year", style: .default) { action in
			self.actionMute(at: indexPath, until: 8760)
		})
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

		present(alert, animated: true)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionMute(at indexPath: IndexPath, until hours: Int) {

		let seconds = TimeInterval(hours * 60 * 60)
		let dateUntil = Date().addingTimeInterval(seconds)
		let mutedUntil = dateUntil.timestamp()

		let chat = chats[indexPath.row]
		Details.update(chatId: chat.objectId, mutedUntil: mutedUntil)
	}

	// MARK: - Cleanup methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc func actionCleanup() {

		tokenMembers?.invalidate()
		tokenChats?.invalidate()

		members	= realm.objects(Member.self).filter(falsepredicate)
		chats	= realm.objects(Chat.self).filter(falsepredicate)

		refreshTableView()
	}
}

// MARK: - SelectUserDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension ChatsView: SelectUserDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func didSelectUser(person: Person) {

		let chatId = Singles.create(person.objectId)
		actionChatPrivate(chatId: chatId, recipientId: person.objectId)
	}
}

// MARK: - UIScrollViewDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension ChatsView: UIScrollViewDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {

		view.endEditing(true)
	}
}

// MARK: - UITableViewDataSource
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension ChatsView: UITableViewDataSource {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func numberOfSections(in tableView: UITableView) -> Int {

		return 1
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

		return chats.count
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

		let cell = tableView.dequeueReusableCell(withIdentifier: "ChatsCell", for: indexPath) as! ChatsCell

		let chat = chats[indexPath.row]
		cell.bindData(chat: chat)
		cell.loadImage(chat: chat, tableView: tableView, indexPath: indexPath)

		return cell
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {

		return true
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

		let actionDelete = UIContextualAction(style: .destructive, title: "Delete") {  action, sourceView, completionHandler in
			self.actionDelete(at: indexPath)
			completionHandler(false)
		}

		let actionMore = UIContextualAction(style: .normal, title: "More") {  action, sourceView, completionHandler in
			self.actionMore(at: indexPath)
			completionHandler(false)
		}

		actionDelete.image = UIImage(systemName: "trash")
		actionMore.image = UIImage(systemName: "ellipsis")

		return UISwipeActionsConfiguration(actions: [actionDelete, actionMore])
	}
}

// MARK: - UITableViewDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension ChatsView: UITableViewDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

		tableView.deselectRow(at: indexPath, animated: true)

		let chat = chats[indexPath.row]

		if (chat.isGroup) {
			actionChatGroup(chatId: chat.objectId)
		}
		if (chat.isPrivate) {
			actionChatPrivate(chatId: chat.objectId, recipientId: chat.userId)
		}
	}
}

// MARK: - UISearchBarDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension ChatsView: UISearchBarDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

		loadChats(text: searchText)
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
		loadChats()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func searchBarSearchButtonClicked(_ searchBar_: UISearchBar) {

		searchBar.resignFirstResponder()
	}
}
