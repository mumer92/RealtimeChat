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
class FireUpdater: NSObject {

	private var collection: String = ""

	private var updating = false

	private var objects: Results<SyncObject>?

	//---------------------------------------------------------------------------------------------------------------------------------------------
	init(name: String, type: SyncObject.Type) {

		super.init()

		collection = name

		let predicate = NSPredicate(format: "syncRequired == YES")
		objects = realm.objects(type).filter(predicate).sorted(byKeyPath: "updatedAt")

		Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
			if (AuthUser.userId() != "") {
				if (Connectivity.isReachable()) {
					self.updateNextObject()
				}
			}
		}
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func updateNextObject() {

		if (updating) { return }

		if let object = objects?.first {
			updateObject(object)
		}
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func updateObject(_ object: SyncObject) {

		updating = true

		let values = populateObject(object)

		if (object.neverSynced) {
			Firestore.firestore().collection(collection).document(object.objectId).setData(values) { error in
				if (error == nil) {
					object.updateSynced()
				}
				self.updating = false
			}
		} else {
			Firestore.firestore().collection(collection).document(object.objectId).updateData(values) { error in
				if (error == nil) {
					object.updateSynced()
				}
				self.updating = false
			}
		}
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func populateObject(_ object: SyncObject) -> [String: Any] {

		var values: [String: Any] = [:]

		for property in object.objectSchema.properties {
			let name = property.name
			if (name != "neverSynced") && (name != "syncRequired") {
				switch property.type {
					case .int:		if let value = object[name] as? Int64	{ values[name] = value }
					case .bool:		if let value = object[name] as? Bool	{ values[name] = value }
					case .float:	if let value = object[name] as? Float	{ values[name] = value }
					case .double:	if let value = object[name] as? Double	{ values[name] = value }
					case .string:	if let value = object[name] as? String	{ values[name] = value }
					case .date:		if let value = object[name] as? Date	{ values[name] = value }
					default:		print("Property type \(property.type.rawValue) is not populated.")
				}
			}
		}
		return values
	}
}
