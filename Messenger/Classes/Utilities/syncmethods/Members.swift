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
class Members: NSObject {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func create(chatId: String, userIds: [String]) {

		let realm = try! Realm()
		try! realm.safeWrite {
			for userId in userIds {
				let member = Member()
				member.objectId = "\(chatId)-\(userId)".md5()
				member.chatId = chatId
				member.userId = userId
				realm.add(member, update: .modified)
			}
		}
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func update(chatId: String, userIds: [String]) {

		var userIds = userIds

		let predicate = NSPredicate(format: "chatId == %@ AND userId IN %@", chatId, userIds)
		let members = realm.objects(Member.self).filter(predicate)

		for member in members {
			member.update(isActive: true)
			userIds.removeObject(member.userId)
		}

		self.create(chatId: chatId, userIds: userIds)
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func update(chatId: String, userId: String, isActive: Bool) {

		let predicate = NSPredicate(format: "chatId == %@ AND userId == %@", chatId, userId)
		if let member = realm.objects(Member.self).filter(predicate).first {
			member.update(isActive: isActive)
		}
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func chatIds() -> [String]? {

		let predicate = NSPredicate(format: "userId == %@", AuthUser.userId())
		let members = realm.objects(Member.self).filter(predicate)

		if (members.count == 0) { return nil }

		var chatIds: [String] = []
		for member in members {
			chatIds.append(member.chatId)
		}
		return chatIds
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func chatIds() -> [String] {

		let predicate = NSPredicate(format: "userId == %@ AND isActive == YES", AuthUser.userId())
		let members = realm.objects(Member.self).filter(predicate)

		var chatIds: [String] = []
		for member in members {
			chatIds.append(member.chatId)
		}
		return chatIds
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func userIds(chatId: String) -> [String] {

		let predicate = NSPredicate(format: "chatId == %@ AND isActive == YES", chatId)
		let members = realm.objects(Member.self).filter(predicate)

		var userIds: [String] = []
		for member in members {
			userIds.append(member.userId)
		}
		return userIds
	}
}
