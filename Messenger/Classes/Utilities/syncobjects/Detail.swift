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

//-------------------------------------------------------------------------------------------------------------------------------------------------
class Detail: SyncObject {

	@objc dynamic var chatId = ""
	@objc dynamic var userId = ""

	@objc dynamic var typing = false
	@objc dynamic var lastRead: Int64 = 0
	@objc dynamic var mutedUntil: Int64 = 0

	@objc dynamic var isDeleted = false
	@objc dynamic var isArchived = false

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func update(typing value: Bool) {

		if (typing == value) { return }

		let realm = try! Realm()
		try! realm.safeWrite {
			typing = value
			syncRequired = true
			updatedAt = Date().timestamp()
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func update(lastRead value: Int64) {

		if (lastRead == value) { return }

		let realm = try! Realm()
		try! realm.safeWrite {
			lastRead = value
			syncRequired = true
			updatedAt = Date().timestamp()
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func update(mutedUntil value: Int64) {

		if (mutedUntil == value) { return }

		let realm = try! Realm()
		try! realm.safeWrite {
			mutedUntil = value
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

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func update(isArchived value: Bool) {

		if (isArchived == value) { return }

		let realm = try! Realm()
		try! realm.safeWrite {
			isArchived = value
			syncRequired = true
			updatedAt = Date().timestamp()
		}
	}
}
