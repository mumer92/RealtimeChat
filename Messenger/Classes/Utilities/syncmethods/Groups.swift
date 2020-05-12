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
class Groups: NSObject {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func create(_ name: String, userIds: [String]) {

		let group = Group()

		group.chatId	= group.objectId

		group.name		= name
		group.ownerId	= AuthUser.userId()

		let realm = try! Realm()
		try! realm.safeWrite {
			realm.add(group, update: .modified)
		}

		Details.create(chatId: group.chatId, userIds: userIds)
		Members.create(chatId: group.chatId, userIds: userIds)
	}
}
