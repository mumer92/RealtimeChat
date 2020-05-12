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

import FirebaseAuth

//-------------------------------------------------------------------------------------------------------------------------------------------------
class AuthUser: NSObject {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func userId() -> String {

		if let currentUser = Auth.auth().currentUser {
			return currentUser.uid
		}
		return ""
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func signIn(email: String, password: String, completion: @escaping (_ error: Error?) -> Void) {

		Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
			completion(error)
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func signUp(email: String, password: String, completion: @escaping (_ error: Error?) -> Void) {

		Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
			completion(error)
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func signIn(credential: AuthCredential, completion: @escaping (_ error: Error?) -> Void) {

		Auth.auth().signIn(with: credential) { authResult, error in
			completion(error)
		}
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func checkPassword(password: String, completion: @escaping (_ error: Error?) -> Void) {

		guard let firuser = Auth.auth().currentUser else {
			fatalError("AuthUser.checkPassword currentUser error.")
		}

		guard let email = firuser.email else {
			fatalError("AuthUser.checkPassword firuser.email error.")
		}

		let credential = EmailAuthProvider.credential(withEmail: email, password: password)
		firuser.reauthenticate(with: credential) { authResult, error in
			completion(error)
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func updatePassword(password: String, completion: @escaping (_ error: Error?) -> Void) {

		guard let firuser = Auth.auth().currentUser else {
			fatalError("AuthUser.updatePassword currentUser error.")
		}

		firuser.updatePassword(to: password) { error in
			completion(error)
		}
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func logOut() {

		try! Auth.auth().signOut()
	}
}
