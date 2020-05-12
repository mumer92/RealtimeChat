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
class Single: SyncObject {

	@objc dynamic var chatId = ""

	@objc dynamic var userId1 = ""
	@objc dynamic var fullname1 = ""
	@objc dynamic var initials1 = ""
	@objc dynamic var pictureAt1: Int64 = 0

	@objc dynamic var userId2 = ""
	@objc dynamic var fullname2 = ""
	@objc dynamic var initials2 = ""
	@objc dynamic var pictureAt2: Int64 = 0
}
