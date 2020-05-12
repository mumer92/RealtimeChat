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
import IQKeyboardManagerSwift

//-------------------------------------------------------------------------------------------------------------------------------------------------
class EditProfileView: UIViewController {

	@IBOutlet var tableView: UITableView!
	@IBOutlet var viewHeader: UIView!
	@IBOutlet var imageUser: UIImageView!
	@IBOutlet var labelInitials: UILabel!
	@IBOutlet var cellFirstname: UITableViewCell!
	@IBOutlet var cellLastname: UITableViewCell!
	@IBOutlet var cellCountry: UITableViewCell!
	@IBOutlet var cellLocation: UITableViewCell!
	@IBOutlet var cellPhone: UITableViewCell!
	@IBOutlet var fieldFirstname: UITextField!
	@IBOutlet var fieldLastname: UITextField!
	@IBOutlet var labelPlaceholder: UILabel!
	@IBOutlet var labelCountry: UILabel!
	@IBOutlet var fieldLocation: UITextField!
	@IBOutlet var fieldPhone: UITextField!

	private var person: Person!
	private var isOnboard = false
	private var heightView: CGFloat = 0

	//---------------------------------------------------------------------------------------------------------------------------------------------
	init(isOnboard: Bool) {

		super.init(nibName: nil, bundle: nil)

		self.isOnboard = isOnboard
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	required init?(coder aDecoder: NSCoder) {

		super.init(coder: aDecoder)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func viewDidLoad() {

		super.viewDidLoad()
		title = "Edit Profile"

		navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(actionDismiss))
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(actionDone))

		IQKeyboardManager.shared.enable = true
		IQKeyboardManager.shared.enableAutoToolbar = false

		let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
		tableView.addGestureRecognizer(gestureRecognizer)
		gestureRecognizer.cancelsTouchesInView = false

		tableView.tableHeaderView = viewHeader

		loadPerson()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func viewDidAppear(_ animated: Bool) {

		super.viewDidAppear(animated)

		heightView = self.view.frame.size.height
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func viewWillDisappear(_ animated: Bool) {

		super.viewWillDisappear(animated)

		IQKeyboardManager.shared.enable = false

		dismissKeyboard()
	}

	// MARK: - Keyboard methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc func dismissKeyboard() {

		view.endEditing(true)
	}

	// MARK: - Realm methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func loadPerson() {

		person = realm.object(ofType: Person.self, forPrimaryKey: AuthUser.userId())

		labelInitials.text = person.initials()
		MediaDownload.startUser(person.objectId, pictureAt: person.pictureAt) { image, error in
			if (error == nil) {
				self.imageUser.image = image?.square(to: 70)
				self.labelInitials.text = nil
			}
		}

		fieldFirstname.text = person.firstname
		fieldLastname.text = person.lastname
		labelCountry.text = person.country
		fieldLocation.text = person.location

		fieldPhone.text = person.phone
		fieldPhone.isUserInteractionEnabled = (person.loginMethod != LOGIN_PHONE)

		updateDetails()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func savePerson(firstname: String, lastname: String, country: String, location: String, phone: String) {

		let realm = try! Realm()
		try! realm.safeWrite {
			person.firstname = firstname
			person.lastname	= lastname
			person.fullname	= "\(firstname) \(lastname)"
			person.country = country
			person.location	= location
			person.phone = phone
			person.syncRequired = true
			person.updatedAt = Date().timestamp()
		}
	}

	// MARK: - User actions
	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc func actionDismiss() {

		if (isOnboard) {
			Users.performLogout()
		}
		dismiss(animated: true)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc func actionDone() {

		let firstname = fieldFirstname.text ?? ""
		let lastname = fieldLastname.text ?? ""
		let country = labelCountry.text ?? ""
		let location = fieldLocation.text ?? ""
		let phone = fieldPhone.text ?? ""

		if (firstname.count == 0)	{ ProgressHUD.showError("Firstname must be set.");		return	}
		if (lastname.count == 0)	{ ProgressHUD.showError("Lastname must be set.");		return	}
		if (country.count == 0)		{ ProgressHUD.showError("Country must be set.");		return	}
		if (location.count == 0)	{ ProgressHUD.showError("Location must be set.");		return	}
		if (phone.count == 0)		{ ProgressHUD.showError("Phone number must be set.");	return	}

		savePerson(firstname: firstname, lastname: lastname, country: country, location: location, phone: phone)

		dismiss(animated: true)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	@IBAction func actionPhoto(_ sender: Any) {

		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

		alert.addAction(UIAlertAction(title: "Open Camera", style: .default) { action in
			ImagePicker.cameraPhoto(target: self, edit: true)
		})
		alert.addAction(UIAlertAction(title: "Photo Library", style: .default) { action in
			ImagePicker.photoLibrary(target: self, edit: true)
		})
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

		present(alert, animated: true)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionCountries() {

		let countriesView = CountriesView()
		countriesView.delegate = self
		let navController = NavigationController(rootViewController: countriesView)
		present(navController, animated: true)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func uploadPicture(image: UIImage) {

		let temp = image.square(to: 300)
		if let data = temp.jpegData(compressionQuality: 0.6) {
			MediaUpload.user(AuthUser.userId(), data: data, completion: { error in
				if (error == nil) {
					MediaDownload.saveUser(AuthUser.userId(), data: data)
					self.person.update(pictureAt: Date().timestamp())
					self.imageUser.image = temp.square(to: 70)
					self.labelInitials.text = nil
				} else {
					ProgressHUD.showError("Picture upload error.")
				}
			})
		}
	}

	// MARK: - Helper methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func updateDetails() {

		labelPlaceholder.isHidden = (labelCountry.text != "")
	}
}

// MARK: - UIImagePickerControllerDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension EditProfileView: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {

		if let image = info[.editedImage] as? UIImage {
			uploadPicture(image: image)
		}
		picker.dismiss(animated: true)
	}
}

// MARK: - CountriesDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension EditProfileView: CountriesDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func didSelectCountry(name: String, code: String) {

		labelCountry.text = name
		updateDetails()

		fieldLocation.becomeFirstResponder()
	}
}

// MARK: - UITableViewDataSource
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension EditProfileView: UITableViewDataSource {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func numberOfSections(in tableView: UITableView) -> Int {

		return 2
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

		if (section == 0) { return 4 }
		if (section == 1) { return 1 }

		return 0
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

		if (indexPath.section == 0) && (indexPath.row == 0) { return cellFirstname	}
		if (indexPath.section == 0) && (indexPath.row == 1) { return cellLastname	}
		if (indexPath.section == 0) && (indexPath.row == 2) { return cellCountry	}
		if (indexPath.section == 0) && (indexPath.row == 3) { return cellLocation	}
		if (indexPath.section == 1) && (indexPath.row == 0) { return cellPhone		}

		return UITableViewCell()
	}
}

// MARK: - UITableViewDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension EditProfileView: UITableViewDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

		tableView.deselectRow(at: indexPath, animated: true)

		if (indexPath.section == 0) && (indexPath.row == 2) { actionCountries()		}
	}
}

// MARK: - UITextFieldDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension EditProfileView: UITextFieldDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {

		if (textField == fieldFirstname)	{ fieldLastname.becomeFirstResponder()	}
		if (textField == fieldLastname)		{ actionCountries()						}
		if (textField == fieldLocation)		{ fieldPhone.becomeFirstResponder()		}
		if (textField == fieldPhone)		{ actionDone()							}

		return true
	}
}
