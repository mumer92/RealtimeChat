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

import FirebaseFirestore
import RealmSwift

//-------------------------------------------------------------------------------------------------------------------------------------------------
class FireFetch: NSObject {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func perform(_ query: Query, to type: SyncObject.Type) {

		query.getDocuments() { querySnapshot, error in
			if let snapshot = querySnapshot {
				DispatchQueue.main.async {
					let realm = try! Realm()
					try! realm.safeWrite {
						for documentChange in snapshot.documentChanges {
							let data = documentChange.document.data()
							self.updateRealm(realm, data, type)
						}
					}
				}
			}
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func perform(_ query: Query, to type: SyncObject.Type, completion: @escaping (_ count: Int, _ error: Error?) -> Void) {

		query.getDocuments() { querySnapshot, error in
			if let snapshot = querySnapshot {
				DispatchQueue.main.async {
					let realm = try! Realm()
					try! realm.safeWrite {
						for documentChange in snapshot.documentChanges {
							let data = documentChange.document.data()
							self.updateRealm(realm, data, type)
						}
					}
					completion(snapshot.documentChanges.count, nil)
				}
			} else {
				completion(0, error)
			}
		}
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	private class func updateRealm(_ realm: Realm, _ values: [String: Any], _ type: SyncObject.Type) {

		var temp = values

		temp["neverSynced"] = false
		temp["syncRequired"] = false

		realm.create(type, value: temp, update: .modified)
	}
}
