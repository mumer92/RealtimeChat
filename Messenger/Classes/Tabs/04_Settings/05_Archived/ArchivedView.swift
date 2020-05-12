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
class ArchivedView: UIViewController {

	@IBOutlet var searchBar: UISearchBar!
	@IBOutlet var tableView: UITableView!

	private var tokenMembers: NotificationToken? = nil
	private var tokenChats: NotificationToken? = nil

	private var members	= realm.objects(Member.self).filter(falsepredicate)
	private var chats	= realm.objects(Chat.self).filter(falsepredicate)

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func viewDidLoad() {

		super.viewDidLoad()
		title = "Archived Chats"

		tableView.register(UINib(nibName: "ArchivedCell", bundle: nil), forCellReuseIdentifier: "ArchivedCell")

		tableView.tableFooterView = UIView()

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
	func loadMembers() {

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
		let predicate2 = NSPredicate(format: "isDeleted == NO AND isArchived == YES AND isGroupDeleted == NO")
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
	@objc func refreshTableView() {

		tableView.reloadData()
	}

	// MARK: - User actions
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionChatPrivate(chatId: String, recipientId: String) {

		let privateChatView = RCPrivateChatView(chatId: chatId, recipientId: recipientId)
		navigationController?.pushViewController(privateChatView, animated: true)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionChatGroup(chatId: String) {

		let groupChatView = RCGroupChatView(chatId: chatId)
		navigationController?.pushViewController(groupChatView, animated: true)
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

		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

		alert.addAction(UIAlertAction(title: "Unarchive", style: .default) { action in
			let chat = self.chats[indexPath.row]
			Details.update(chatId: chat.objectId, isArchived: false)
		})
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

		present(alert, animated: true)
	}

	// MARK: - Cleanup methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionCleanup() {

		tokenMembers?.invalidate()
		tokenChats?.invalidate()

		members	= realm.objects(Member.self).filter(falsepredicate)
		chats	= realm.objects(Chat.self).filter(falsepredicate)

		refreshTableView()
	}
}

// MARK: - UIScrollViewDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension ArchivedView: UIScrollViewDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {

		view.endEditing(true)
	}
}

// MARK: - UITableViewDataSource
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension ArchivedView: UITableViewDataSource {

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

		let cell = tableView.dequeueReusableCell(withIdentifier: "ArchivedCell", for: indexPath) as! ArchivedCell

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
extension ArchivedView: UITableViewDelegate {

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
extension ArchivedView: UISearchBarDelegate {

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
