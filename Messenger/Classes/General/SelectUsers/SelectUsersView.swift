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
@objc protocol SelectUsersDelegate: class {

	func didSelectUsers(userIds: [String])
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
class SelectUsersView: UIViewController {

	@IBOutlet weak var delegate: SelectUsersDelegate?

	@IBOutlet var searchBar: UISearchBar!
	@IBOutlet var tableView: UITableView!

	private var persons = realm.objects(Person.self).filter(falsepredicate)

	private var selection: [String] = []
	private var sections: [[Person]] = []
	private let collation = UILocalizedIndexedCollation.current()

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func viewDidLoad() {

		super.viewDidLoad()
		title = "Select Users"

		navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(actionDismiss))
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(actionDone))

		tableView.register(UINib(nibName: "SelectUsersCell", bundle: nil), forCellReuseIdentifier: "SelectUsersCell")

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

	// MARK: - Realm methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func loadPersons(text: String = "") {

		let predicate1 = NSPredicate(format: "objectId IN %@ AND NOT objectId IN %@", Friends.friendIds(), Blockeds.blockerIds())
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
	@objc func actionDismiss() {

		dismiss(animated: true)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc func actionDone() {

		if (selection.count != 0) {
			dismiss(animated: true) {
				self.delegate?.didSelectUsers(userIds: self.selection)
			}
		} else {
			ProgressHUD.showError("Please select some users.")
		}
	}
}

// MARK: - UIScrollViewDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension SelectUsersView: UIScrollViewDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {

		dismissKeyboard()
	}
}

// MARK: - UITableViewDataSource
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension SelectUsersView: UITableViewDataSource {

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

		let cell = tableView.dequeueReusableCell(withIdentifier: "SelectUsersCell", for: indexPath) as! SelectUsersCell

		let person = sections[indexPath.section][indexPath.row]
		cell.bindData(person: person)
		cell.loadImage(person: person, tableView: tableView, indexPath: indexPath)

		cell.accessoryType = selection.contains(person.objectId) ? .checkmark : .none

		return cell
	}
}

// MARK: - UITableViewDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension SelectUsersView: UITableViewDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

		tableView.deselectRow(at: indexPath, animated: true)

		let person = sections[indexPath.section][indexPath.row]

		if (selection.contains(person.objectId)) {
			selection.removeObject(person.objectId)
		} else {
			selection.append(person.objectId)
		}

		if let cell = tableView.cellForRow(at: indexPath) {
			cell.accessoryType = selection.contains(person.objectId) ? .checkmark : .none
		}
	}
}

// MARK: - UISearchBarDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension SelectUsersView: UISearchBarDelegate {

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
