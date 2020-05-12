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
class ArchivedCell: UITableViewCell {

	@IBOutlet var imageUser: UIImageView!
	@IBOutlet var labelInitials: UILabel!
	@IBOutlet var labelDetails: UILabel!
	@IBOutlet var labelLastMessage: UILabel!
	@IBOutlet var labelElapsed: UILabel!
	@IBOutlet var imageMuted: UIImageView!
	@IBOutlet var viewUnread: UIView!
	@IBOutlet var labelUnread: UILabel!

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func bindData(chat: Chat) {

		labelDetails.text = chat.details
		labelLastMessage.text = chat.typing ? "Typing..." : chat.lastMessageText

		labelElapsed.text = Convert.timestampToCustom(chat.lastMessageAt)

		imageMuted.isHidden = (chat.mutedUntil < Date().timestamp())
		viewUnread.isHidden = (chat.unreadCount == 0)

		labelUnread.text = (chat.unreadCount < 100) ? "\(chat.unreadCount)" : "..."
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func loadImage(chat: Chat, tableView: UITableView, indexPath: IndexPath) {

		if (chat.isPrivate) {
			if let path = MediaDownload.pathUser(chat.userId) {
				imageUser.image = UIImage.image(path, size: 50)
				labelInitials.text = nil
			} else {
				imageUser.image = nil
				labelInitials.text = chat.initials
				downloadImage(chat: chat, tableView: tableView, indexPath: indexPath)
			}
		}

		if (chat.isGroup) {
			imageUser.image = nil
			labelInitials.text = chat.initials
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func downloadImage(chat: Chat, tableView: UITableView, indexPath: IndexPath) {

		MediaDownload.startUser(chat.userId, pictureAt: chat.pictureAt) { image, error in
			let indexSelf = tableView.indexPath(for: self)
			if ((indexSelf == nil) || (indexSelf == indexPath)) {
				if (error == nil) {
					self.imageUser.image = image?.square(to: 50)
					self.labelInitials.text = nil
				} else if (error!.code() == 102) {
					DispatchQueue.main.async(after: 0.5) {
						self.downloadImage(chat: chat, tableView: tableView, indexPath: indexPath)
					}
				}
			}
		}
	}
}
