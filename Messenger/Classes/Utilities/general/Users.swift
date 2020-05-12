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
import CoreSpotlight
import ProgressHUD
import RealmSwift

//-------------------------------------------------------------------------------------------------------------------------------------------------
class Users: NSObject {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func login(target: Any) {

		let viewController = target as! UIViewController
		let welcomeView = WelcomeView()
		welcomeView.isModalInPresentation = true
		welcomeView.modalPresentationStyle = .fullScreen
		viewController.present(welcomeView, animated: true) {
			viewController.tabBarController?.selectedIndex = Int(DEFAULT_TAB)
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func onboard(target: Any) {

		let viewController = target as! UIViewController
		let editProfileView = EditProfileView(isOnboard: true)
		let navController = NavigationController(rootViewController: editProfileView)
		navController.isModalInPresentation = true
		navController.modalPresentationStyle = .fullScreen
		viewController.present(navController, animated: true)
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func loggedIn() {

		Shortcut.create()

		if (Persons.fullname() != "") {
			ProgressHUD.showSuccess("Welcome back!")
		} else {
			ProgressHUD.showSuccess("Welcome!")
		}

		NotificationCenter.post(notification: NOTIFICATION_USER_LOGGED_IN)

		DispatchQueue.main.async(after: 0.5) {
			Persons.update(lastActive: Date().timestamp())
			Persons.update(oneSignalId: PushNotification.oneSignalId())
		}
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func prepareLogout() {

		Persons.update(oneSignalId: "")
		Persons.update(lastTerminate: Date().timestamp())
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func performLogout() {

		NotificationCenter.post(notification: NOTIFICATION_USER_LOGGED_OUT)

		MediaManager.cleanupManual(logout: true)

		let realm = try! Realm()
		try! realm.safeWrite {
			realm.deleteAll()
		}

		if let bundleId = Bundle.main.bundleIdentifier {
			CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [bundleId])
		}

		Shortcut.cleanup()

		AuthUser.logOut()
	}
}
