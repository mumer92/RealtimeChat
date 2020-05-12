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
class Friends: NSObject {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func create(_ userId: String) {

		let predicate = NSPredicate(format: "userId == %@ AND friendId == %@", AuthUser.userId(), userId)
		if let friend = realm.objects(Friend.self).filter(predicate).first {
			friend.update(isDeleted: false)
			return
		}

		let realm = try! Realm()
		try! realm.safeWrite {
			let friend = Friend()
			friend.objectId = "\(AuthUser.userId())-\(userId)".md5()
			friend.userId = AuthUser.userId()
			friend.friendId = userId
			realm.add(friend, update: .modified)
		}
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func update(_ userId: String, isDeleted: Bool) {

		let predicate = NSPredicate(format: "userId == %@ AND friendId == %@", AuthUser.userId(), userId)
		if let friend = realm.objects(Friend.self).filter(predicate).first {
			friend.update(isDeleted: isDeleted)
		}
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func isFriend(_ userId: String) -> Bool {

		let predicate = NSPredicate(format: "userId == %@ AND friendId == %@ AND isDeleted == NO", AuthUser.userId(), userId)
		return (realm.objects(Friend.self).filter(predicate).first != nil)
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func friendIds() -> [String] {

		let predicate = NSPredicate(format: "userId == %@ AND isDeleted == NO", AuthUser.userId())
		let friends = realm.objects(Friend.self).filter(predicate)

		var friendIds: [String] = []
		for friend in friends {
			friendIds.append(friend.friendId)
		}
		return friendIds
	}
}
