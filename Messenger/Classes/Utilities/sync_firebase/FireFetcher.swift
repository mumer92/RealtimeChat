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
class FireFetcher: NSObject {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func fetchPerson(_ objectId: String, completion: @escaping (_ error: Error?) -> Void) {

		let query = Firestore.firestore().collection("Person")
			.whereField("objectId", isEqualTo: objectId)
		FireFetch.perform(query, to: Person.self) { count, error in
			if (error == nil) {
				if (count != 0) {
					completion(nil)
				} else {
					completion(NSError.description("No user data found.", code: 100))
				}
			} else {
				completion(error)
			}
		}
	}
}
