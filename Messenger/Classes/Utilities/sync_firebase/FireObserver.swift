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
class FireObserver: NSObject {

	private var query: Query!
	private var type: SyncObject.Type!

	private var listener: ListenerRegistration?

	//---------------------------------------------------------------------------------------------------------------------------------------------
	init(_ query: Query, to type: SyncObject.Type) {

		super.init()

		self.query = query
		self.type = type

		listener = query.addSnapshotListener { querySnapshot, error in
			if let snapshot = querySnapshot {
				DispatchQueue.main.async {
					let realm = try! Realm()
					try! realm.safeWrite {
						for documentChange in snapshot.documentChanges {
							let data = documentChange.document.data()
							self.updateRealm(realm, data)
						}
					}
				}
			}
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	init(_ query: Query, to type: SyncObject.Type, refreshCallback: @escaping (_ insert: Bool, _ modify: Bool) -> Void) {

		super.init()

		self.query = query
		self.type = type

		listener = query.addSnapshotListener { querySnapshot, error in
			if let snapshot = querySnapshot {
				DispatchQueue.main.async(after: 0.1) {
					var insert = false
					var modify = false

					let realm = try! Realm()
					try! realm.safeWrite {
						for documentChange in snapshot.documentChanges {
							if (documentChange.type == .added) { insert = true }
							if (documentChange.type == .modified) { modify = true }
							let data = documentChange.document.data()
							self.updateRealm(realm, data)
						}
					}

					refreshCallback(insert, modify)
				}
			}
		}
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func removeObserver() {

		listener?.remove()
		listener = nil
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func updateRealm(_ realm: Realm, _ values: [String: Any]) {

		var temp = values

		temp["neverSynced"] = false
		temp["syncRequired"] = false

		realm.create(type, value: temp, update: .modified)
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func printDetails(_ text: String, _ snapshot: QuerySnapshot) {

		var delete = "", insert = "", modify = ""

		for documentChange in snapshot.documentChanges {
			if (documentChange.type == .removed)	{ delete = "delete" }
			if (documentChange.type == .added)		{ insert = "insert" }
			if (documentChange.type == .modified)	{ modify = "modify" }
		}

		let source = snapshot.metadata.isFromCache ? "local" : "server"

		print("\(text): \(type.description()) \(snapshot.documentChanges.count) \(source) - \(delete)\(insert)\(modify)")
	}
}
