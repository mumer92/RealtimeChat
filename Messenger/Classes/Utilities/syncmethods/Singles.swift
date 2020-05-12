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
class Singles: NSObject {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func create(_ userId: String) -> String {

		let chatId = self.chatId(userId)
		if (realm.object(ofType: Single.self, forPrimaryKey: chatId) == nil) {

			guard let person = realm.object(ofType: Person.self, forPrimaryKey: userId) else {
				fatalError("Recipient user must exist in the local database.")
			}

			let single = Single()

			single.objectId		= chatId
			single.chatId		= chatId

			single.userId1		= AuthUser.userId()
			single.fullname1	= Persons.fullname()
			single.initials1	= Persons.initials()
			single.pictureAt1	= Persons.pictureAt()

			single.userId2		= userId
			single.fullname2	= person.fullname
			single.initials2	= person.initials()
			single.pictureAt2	= person.pictureAt

			let realm = try! Realm()
			try! realm.safeWrite {
				realm.add(single, update: .modified)
			}

			let userIds = [AuthUser.userId(), userId]
			Details.create(chatId: chatId, userIds: userIds)
			Members.create(chatId: chatId, userIds: userIds)
		}

		return chatId
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func chatId(_ userId: String) -> String {

		let userIds = [AuthUser.userId(), userId]

		let sorted = userIds.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
		let joined = sorted.joined(separator: "")

		return joined.md5()
	}
}
