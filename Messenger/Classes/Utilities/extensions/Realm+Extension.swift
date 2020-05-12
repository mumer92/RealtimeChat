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
extension Realm {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	public func safeWrite(_ block: (() throws -> Void)) throws {

		if (isInWriteTransaction) {
			try block()
		} else {
			try write(block)
		}
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
extension Results {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	public func safeObserve(_ block: @escaping (RealmCollectionChange<Results>) -> Void, completion: @escaping (NotificationToken) -> Void) {

		let realm = try! Realm()
		if (!realm.isInWriteTransaction) {
			let token = self.observe(block)
			completion(token)
		} else {
			DispatchQueue.main.async(after: 0.1) {
				self.safeObserve(block, completion: completion)
			}
		}
	}
}
