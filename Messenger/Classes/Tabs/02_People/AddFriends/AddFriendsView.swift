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
class AddFriendsView: UIViewController {

	@IBOutlet var searchBar: UISearchBar!
	@IBOutlet var tableView: UITableView!

	private var persons = realm.objects(Person.self).filter(falsepredicate)

	private var sections: [[Person]] = []
	private let collation = UILocalizedIndexedCollation.current()

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func viewDidLoad() {

		super.viewDidLoad()
		title = "Add Friends"

		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(actionDone))

		tableView.register(UINib(nibName: "AddFriendsCell", bundle: nil), forCellReuseIdentifier: "AddFriendsCell")

		tableView.tableFooterView = UIView()

		loadPersons()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func viewWillDisappear(_ animated: Bool) {

		super.viewWillDisappear(animated)

		dismissKeyboard()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func dismissKeyboard() {

		view.endEditing(true)
	}

	// MARK: - Backend methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func loadPersons(text: String = "") {

		let predicate1 = NSPredicate(format: "objectId != %@", AuthUser.userId())
		let predicate2 = (text != "") ? NSPredicate(format: "fullname CONTAINS[c] %@", text) : NSPredicate(value: true)

		persons = realm.objects(Person.self).filter(predicate1).filter(predicate2).sorted(byKeyPath: "fullname")

		refreshTableView()
	}

	// MARK: - Refresh methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func refreshTableView() {

		setObjects()
		tableView.reloadData()
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

	// MARK: - User actions
	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc func actionDone() {

		dismiss(animated: true)
	}
}

// MARK: - UIScrollViewDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension AddFriendsView: UIScrollViewDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {

		dismissKeyboard()
	}
}

// MARK: - UITableViewDataSource
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension AddFriendsView: UITableViewDataSource {

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

		let cell = tableView.dequeueReusableCell(withIdentifier: "AddFriendsCell", for: indexPath) as! AddFriendsCell

		let person = sections[indexPath.section][indexPath.row]
		cell.bindData(person: person)
		cell.loadImage(person: person, tableView: tableView, indexPath: indexPath)

		return cell
	}
}

// MARK: - UITableViewDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension AddFriendsView: UITableViewDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

		tableView.deselectRow(at: indexPath, animated: true)

		let person = sections[indexPath.section][indexPath.row]

		if (Friends.isFriend(person.objectId)) {
			ProgressHUD.showSuccess("Already added.")
		} else {
			Friends.create(person.objectId)
			ProgressHUD.showSuccess("Friend added.")
		}
	}
}

// MARK: - UISearchBarDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension AddFriendsView: UISearchBarDelegate {

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
