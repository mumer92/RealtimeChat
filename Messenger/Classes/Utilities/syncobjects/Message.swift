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
import CoreLocation

//-------------------------------------------------------------------------------------------------------------------------------------------------
class Message: SyncObject {

	@objc dynamic var chatId = ""

	@objc dynamic var userId = ""
	@objc dynamic var userFullname = ""
	@objc dynamic var userInitials = ""
	@objc dynamic var userPictureAt: Int64 = 0

	@objc dynamic var type = ""
	@objc dynamic var text = ""

	@objc dynamic var photoWidth: Int = 0
	@objc dynamic var photoHeight: Int = 0
	@objc dynamic var videoDuration: Int = 0
	@objc dynamic var audioDuration: Int = 0

	@objc dynamic var latitude: CLLocationDegrees = 0
	@objc dynamic var longitude: CLLocationDegrees = 0

	@objc dynamic var isMediaQueued = false
	@objc dynamic var isMediaFailed = false

	@objc dynamic var isDeleted = false

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func lastUpdatedAt(_ chatId: String) -> Int64 {

		let realm = try! Realm()
		let predicate = NSPredicate(format: "chatId == %@", chatId)
		let object = realm.objects(Message.self).filter(predicate).sorted(byKeyPath: "updatedAt").last
		return object?.updatedAt ?? 0
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func update(isMediaQueued value: Bool) {

		if (isMediaQueued == value) { return }

		let realm = try! Realm()
		try! realm.safeWrite {
			isMediaQueued = value
			syncRequired = true
			updatedAt = Date().timestamp()
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func update(isMediaFailed value: Bool) {

		if (isMediaFailed == value) { return }

		let realm = try! Realm()
		try! realm.safeWrite {
			isMediaFailed = value
			syncRequired = true
			updatedAt = Date().timestamp()
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func update(isDeleted value: Bool) {

		if (isDeleted == value) { return }

		let realm = try! Realm()
		try! realm.safeWrite {
			isDeleted = value
			syncRequired = true
			updatedAt = Date().timestamp()
		}
	}
}
