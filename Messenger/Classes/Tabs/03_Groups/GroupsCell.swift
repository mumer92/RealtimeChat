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

import UIKit

//-------------------------------------------------------------------------------------------------------------------------------------------------
class GroupsCell: UITableViewCell {

	@IBOutlet var imageGroup: UIImageView!
	@IBOutlet var labelInitials: UILabel!
	@IBOutlet var labelName: UILabel!
	@IBOutlet var labelMembers: UILabel!

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func bindData(group: Group) {

		labelInitials.text = String(group.name.prefix(1))

		labelName.text = group.name

		let userIds = Members.userIds(chatId: group.chatId)
		labelMembers.text = "\(userIds.count) members"
	}
}
