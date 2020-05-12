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

import ProgressHUD

//-------------------------------------------------------------------------------------------------------------------------------------------------
@objc protocol LoginEmailDelegate: class {

	func didLoginUserEmail()
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
class LoginEmailView: UIViewController {

	@IBOutlet weak var delegate: LoginEmailDelegate?

	@IBOutlet var fieldEmail: UITextField!
	@IBOutlet var fieldPassword: UITextField!

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func viewDidLoad() {

		super.viewDidLoad()

		let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
		view.addGestureRecognizer(gestureRecognizer)
		gestureRecognizer.cancelsTouchesInView = false
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func viewWillDisappear(_ animated: Bool) {

		super.viewWillDisappear(animated)

		dismissKeyboard()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc func dismissKeyboard() {

		view.endEditing(true)
	}

	// MARK: - User actions
	//---------------------------------------------------------------------------------------------------------------------------------------------
	@IBAction func actionDismiss(_ sender: Any) {

		dismiss(animated: true)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	@IBAction func actionLogin(_ sender: Any) {

		let email = (fieldEmail.text ?? "").lowercased()
		let password = fieldPassword.text ?? ""

		if (email.count == 0)		{ ProgressHUD.showError("Please enter your email.");	return }
		if (password.count == 0)	{ ProgressHUD.showError("Please enter your password.");	return }

		actionLogin(email: email, password: password)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionLogin(email: String, password: String) {

		ProgressHUD.show(nil, interaction: false)

		AuthUser.signIn(email: email, password: password) { error in
			if let error = error {
				ProgressHUD.showError(error.localizedDescription)
			} else {
				self.loadPerson()
			}
		}
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func loadPerson() {

		let userId = AuthUser.userId()
		FireFetcher.fetchPerson(userId) { error in
			if (error != nil) {
				self.createPerson()
			}
			self.dismiss(animated: true) {
				self.delegate?.didLoginUserEmail()
			}
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func createPerson() {

		let email = (fieldEmail.text ?? "").lowercased()

		let userId = AuthUser.userId()
		Persons.create(userId, email: email)
	}
}

// MARK: - UITextFieldDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension LoginEmailView: UITextFieldDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {

		if (textField == fieldEmail) {
			fieldPassword.becomeFirstResponder()
		}
		if (textField == fieldPassword) {
			actionLogin(0)
		}
		return true
	}
}
