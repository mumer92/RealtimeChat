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
import CoreSpotlight
import MobileCoreServices

//-------------------------------------------------------------------------------------------------------------------------------------------------
class PeopleView: UIViewController {

	@IBOutlet var viewTitle: UIView!
	@IBOutlet var labelTitle: UILabel!
	@IBOutlet var searchBar: UISearchBar!
	@IBOutlet var tableView: UITableView!

	private var tokenFriends: NotificationToken? = nil
	private var tokenBlockeds: NotificationToken? = nil
	private var tokenPersons: NotificationToken? = nil

	private var friends = realm.objects(Friend.self).filter(falsepredicate)
	private var blockeds = realm.objects(Blocked.self).filter(falsepredicate)
	private var persons = realm.objects(Person.self).filter(falsepredicate)

	private var sections: [[Person]] = []
	private let collation = UILocalizedIndexedCollation.current()

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {

		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

		tabBarItem.image = UIImage(systemName: "person.crop.circle")
		tabBarItem.title = "People"

		NotificationCenter.addObserver(target: self, selector: #selector(loadFriends), name: NOTIFICATION_USER_LOGGED_IN)
		NotificationCenter.addObserver(target: self, selector: #selector(loadBlockeds), name: NOTIFICATION_USER_LOGGED_IN)
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

		navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(actionAddFriends))

		tableView.register(UINib(nibName: "PeopleCell", bundle: nil), forCellReuseIdentifier: "PeopleCell")

		tableView.tableFooterView = UIView()

		if (AuthUser.userId() != "") {
			loadFriends()
			loadBlockeds()
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
	@objc func loadFriends() {

		let predicate = NSPredicate(format: "userId == %@ AND isDeleted == NO", AuthUser.userId())
		friends = realm.objects(Friend.self).filter(predicate)

		tokenFriends?.invalidate()
		friends.safeObserve({ changes in
			self.loadPersons()
		}, completion: { token in
			self.tokenFriends = token
		})
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc func loadBlockeds() {

		let predicate = NSPredicate(format: "blockedId == %@ AND isDeleted == NO", AuthUser.userId())
		blockeds = realm.objects(Blocked.self).filter(predicate)

		tokenBlockeds?.invalidate()
		blockeds.safeObserve({ changes in
			self.loadPersons()
		}, completion: { token in
			self.tokenBlockeds = token
		})
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func loadPersons(text: String = "") {

		let predicate1 = NSPredicate(format: "objectId IN %@ AND NOT objectId IN %@", Friends.friendIds(), Blockeds.blockerIds())
		let predicate2 = (text != "") ? NSPredicate(format: "fullname CONTAINS[c] %@", text) : NSPredicate(value: true)

		persons = realm.objects(Person.self).filter(predicate1).filter(predicate2).sorted(byKeyPath: "fullname")

		tokenPersons?.invalidate()
		persons.safeObserve({ changes in
			self.refreshTableView()
		}, completion: { token in
			self.tokenPersons = token
		})
	}

	// MARK: - Refresh methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc func refreshTableView() {

		setObjects()
		tableView.reloadData()

		labelTitle.text = "(\(persons.count) friends)"

		DispatchQueue.main.async(after: 1.0) {
			self.setSpotlightSearch()
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func setObjects() {

		sections.removeAll()

		let selector = #selector(getter: Person.fullname)
		sections = Array(repeating: [], count: collation.sectionTitles.count)

		if let sorted = collation.sortedArray(from: Array(persons), collationStringSelector: selector) as? [Person] {
			for person in sorted {
				let section = collation.section(for: person, collationStringSelector: selector)
				sections[section].append(person)
			}
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func setSpotlightSearch() {

		var items: [CSSearchableItem] = []

		guard let bundleId = Bundle.main.bundleIdentifier else { return }

		for person in persons {
			let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
			attributeSet.title = person.fullname
			attributeSet.displayName = person.fullname
			attributeSet.contentDescription = person.country
			attributeSet.keywords = [person.firstname, person.lastname, person.country]

			if let path = MediaDownload.pathUser(person.objectId) {
				attributeSet.thumbnailURL = URL(fileURLWithPath: path)
			}

			items.append(CSSearchableItem(uniqueIdentifier: person.objectId, domainIdentifier: bundleId, attributeSet: attributeSet))
		}

		CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [bundleId], completionHandler: { error in
			if (error == nil) {
				CSSearchableIndex.default().indexSearchableItems(items)
			}
		})
	}

	// MARK: - User actions
	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc func actionAddFriends() {

		let addFriendsView = AddFriendsView()
		let navController = NavigationController(rootViewController: addFriendsView)
		present(navController, animated: true)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionUser(userId: String) {

		if (tabBarController?.tabBar.isHidden ?? true) { return }

		tabBarController?.selectedIndex = 1

		actionProfile(userId: userId)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionProfile(userId: String) {

		let profileView = ProfileView(userId: userId, chat: true)
		profileView.hidesBottomBarWhenPushed = true
		navigationController?.pushViewController(profileView, animated: true)
	}

	// MARK: - Cleanup methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc func actionCleanup() {

		tokenFriends?.invalidate()
		tokenBlockeds?.invalidate()
		tokenPersons?.invalidate()

		friends = realm.objects(Friend.self).filter(falsepredicate)
		blockeds = realm.objects(Blocked.self).filter(falsepredicate)
		persons = realm.objects(Person.self).filter(falsepredicate)

		refreshTableView()
	}
}

// MARK: - UIScrollViewDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension PeopleView: UIScrollViewDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {

		view.endEditing(true)
	}
}

// MARK: - UITableViewDataSource
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension PeopleView: UITableViewDataSource {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func numberOfSections(in tableView: UITableView) -> Int {

		return sections.count
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

		return sections[section].count
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

		return (sections[section].count != 0) ? collation.sectionTitles[section] : nil
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func sectionIndexTitles(for tableView: UITableView) -> [String]? {

		return collation.sectionIndexTitles
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {

		return collation.section(forSectionIndexTitle: index)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

		let cell = tableView.dequeueReusableCell(withIdentifier: "PeopleCell", for: indexPath) as! PeopleCell

		let person = sections[indexPath.section][indexPath.row]
		cell.bindData(person: person)
		cell.loadImage(person: person, tableView: tableView, indexPath: indexPath)

		return cell
	}
}

// MARK: - UITableViewDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension PeopleView: UITableViewDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

		tableView.deselectRow(at: indexPath, animated: true)

		let person = sections[indexPath.section][indexPath.row]
		actionProfile(userId: person.objectId)
	}
}

// MARK: - UISearchBarDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension PeopleView: UISearchBarDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

		loadPersons(text: searchText)
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
		loadPersons()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func searchBarSearchButtonClicked(_ searchBar_: UISearchBar) {

		searchBar.resignFirstResponder()
	}
}
