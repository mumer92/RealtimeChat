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
class Chat: Object {

	@objc dynamic var objectId = ""

	@objc dynamic var isGroup = false
	@objc dynamic var isPrivate = false

	@objc dynamic var details = ""
	@objc dynamic var initials = ""

	@objc dynamic var userId = ""
	@objc dynamic var pictureAt: Int64 = 0

	@objc dynamic var lastMessageId = ""
	@objc dynamic var lastMessageText = ""
	@objc dynamic var lastMessageAt: Int64 = 0

	@objc dynamic var typing = false
	@objc dynamic var lastRead: Int64 = 0
	@objc dynamic var mutedUntil: Int64 = 0
	@objc dynamic var unreadCount: Int = 0

	@objc dynamic var isDeleted = false
	@objc dynamic var isArchived = false

	@objc dynamic var isGroupDeleted = false

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override static func primaryKey() -> String? {

		return "objectId"
	}
}
