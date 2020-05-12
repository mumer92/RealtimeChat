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
import CryptoSwift

//-------------------------------------------------------------------------------------------------------------------------------------------------
class Blockeds: NSObject {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func create(_ userId: String) {

		let predicate = NSPredicate(format: "blockerId == %@ AND blockedId == %@", AuthUser.userId(), userId)
		if let blocked = realm.objects(Blocked.self).filter(predicate).first {
			blocked.update(isDeleted: false)
			return
		}

		let realm = try! Realm()
		try! realm.safeWrite {
			let blocked = Blocked()
			blocked.objectId = "\(AuthUser.userId())-\(userId)".md5()
			blocked.blockerId = AuthUser.userId()
			blocked.blockedId = userId
			realm.add(blocked, update: .modified)
		}
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func update(_ userId: String, isDeleted: Bool) {

		let predicate = NSPredicate(format: "blockerId == %@ AND blockedId == %@", AuthUser.userId(), userId)
		if let blocked = realm.objects(Blocked.self).filter(predicate).first {
			blocked.update(isDeleted: isDeleted)
		}
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func isBlocker(_ userId: String) -> Bool {

		let predicate = NSPredicate(format: "blockerId == %@ AND blockedId == %@ AND isDeleted == NO", userId, AuthUser.userId())
		return (realm.objects(Blocked.self).filter(predicate).first != nil)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func isBlocked(_ userId: String) -> Bool {

		let predicate = NSPredicate(format: "blockerId == %@ AND blockedId == %@ AND isDeleted == NO", AuthUser.userId(), userId)
		return (realm.objects(Blocked.self).filter(predicate).first != nil)
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func blockerIds() -> [String] {

		let predicate = NSPredicate(format: "blockedId == %@ AND isDeleted == NO", AuthUser.userId())
		let blockeds = realm.objects(Blocked.self).filter(predicate)

		var blockerIds: [String] = []
		for blocked in blockeds {
			blockerIds.append(blocked.blockerId)
		}
		return blockerIds
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func blockedIds() -> [String] {

		let predicate = NSPredicate(format: "blockerId == %@ AND isDeleted == NO", AuthUser.userId())
		let blockeds = realm.objects(Blocked.self).filter(predicate)

		var blockedIds: [String] = []
		for blocked in blockeds {
			blockedIds.append(blocked.blockedId)
		}
		return blockedIds
	}
}
