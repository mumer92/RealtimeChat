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
class BlockedView: UIViewController {

	@IBOutlet var searchBar: UISearchBar!
	@IBOutlet var tableView: UITableView!

	private var persons = realm.objects(Person.self).filter(falsepredicate)

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func viewDidLoad() {

		super.viewDidLoad()
		title = "Blocked Users"

		navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)

		tableView.register(UINib(nibName: "BlockedCell", bundle: nil), forCellReuseIdentifier: "BlockedCell")

		tableView.tableFooterView = UIView()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func viewWillAppear(_ animated: Bool) {

		super.viewWillAppear(animated)

		loadPersons()
	}

	// MARK: - Realm methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func loadPersons(text: String = "") {

		let predicate1 = NSPredicate(format: "objectId IN %@", Blockeds.blockedIds())
		let predicate2 = (text != "") ? NSPredicate(format: "fullname CONTAINS[c] %@", text) : NSPredicate(value: true)

		persons = realm.objects(Person.self).filter(predicate1).filter(predicate2).sorted(byKeyPath: "fullname")

		refreshTableView()
	}

	// MARK: - Refresh methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func refreshTableView() {

		tableView.reloadData()
	}
}

// MARK: - UIScrollViewDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension BlockedView: UIScrollViewDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {

		view.endEditing(true)
	}
}

// MARK: - UITableViewDataSource
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension BlockedView: UITableViewDataSource {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func numberOfSections(in tableView: UITableView) -> Int {

		return 1
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

		return persons.count
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

		let cell = tableView.dequeueReusableCell(withIdentifier: "BlockedCell", for: indexPath) as! BlockedCell

		let person = persons[indexPath.row]
		cell.bindData(person: person)
		cell.loadImage(person: person, tableView: tableView, indexPath: indexPath)

		return cell
	}
}

// MARK: - UITableViewDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension BlockedView: UITableViewDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

		tableView.deselectRow(at: indexPath, animated: true)

		let person = persons[indexPath.row]

		let profileView = ProfileView(userId: person.objectId, chat: true)
		navigationController?.pushViewController(profileView, animated: true)
	}
}

// MARK: - UISearchBarDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension BlockedView: UISearchBarDelegate {

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
