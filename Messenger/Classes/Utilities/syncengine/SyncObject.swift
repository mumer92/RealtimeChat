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
class SyncObject: Object {

	@objc dynamic var objectId: String = UUID().uuidString

	@objc dynamic var neverSynced: Bool = true
	@objc dynamic var syncRequired: Bool = true

	@objc dynamic var createdAt: Int64 = Date().timestamp()
	@objc dynamic var updatedAt: Int64 = Date().timestamp()

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override static func primaryKey() -> String? {

		return "objectId"
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func updateSynced() {

		if (syncRequired) || (neverSynced) {
			let realm = try! Realm()
			try! realm.safeWrite {
				neverSynced = false
				syncRequired = false
			}
		}
	}
}
