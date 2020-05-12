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
class Details: NSObject {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func create(chatId: String, userIds: [String]) {

		let realm = try! Realm()
		try! realm.safeWrite {
			for userId in userIds {
				let detail = Detail()
				detail.objectId = "\(chatId)-\(userId)".md5()
				detail.chatId = chatId
				detail.userId = userId
				realm.add(detail, update: .modified)
			}
		}
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func update(chatId: String, userIds: [String]) {

		var userIds = userIds

		let predicate = NSPredicate(format: "chatId == %@ AND userId IN %@", chatId, userIds)
		let details = realm.objects(Detail.self).filter(predicate)

		for detail in details {
			userIds.removeObject(detail.userId)
		}

		self.create(chatId: chatId, userIds: userIds)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func update(chatId: String, mutedUntil: Int64) {

		let predicate = NSPredicate(format: "chatId == %@ AND userId == %@", chatId, AuthUser.userId())
		if let detail = realm.objects(Detail.self).filter(predicate).first {
			detail.update(mutedUntil: mutedUntil)
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func update(chatId: String, isDeleted: Bool) {

		let predicate = NSPredicate(format: "chatId == %@ AND userId == %@", chatId, AuthUser.userId())
		if let detail = realm.objects(Detail.self).filter(predicate).first {
			detail.update(isDeleted: isDeleted)
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func update(chatId: String, isArchived: Bool) {

		let predicate = NSPredicate(format: "chatId == %@ AND userId == %@", chatId, AuthUser.userId())
		if let detail = realm.objects(Detail.self).filter(predicate).first {
			detail.update(isArchived: isArchived)
		}
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func updateAll(chatId: String, isDeleted: Bool) {

		let predicate = NSPredicate(format: "chatId == %@", chatId)
		for detail in realm.objects(Detail.self).filter(predicate) {
			detail.update(isDeleted: isDeleted)
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func updateAll(chatId: String, isArchived: Bool) {

		let predicate = NSPredicate(format: "chatId == %@", chatId)
		for detail in realm.objects(Detail.self).filter(predicate) {
			detail.update(isArchived: isArchived)
		}
	}
}
