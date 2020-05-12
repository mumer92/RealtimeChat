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
class BlockedCell: UITableViewCell {

	@IBOutlet var imageUser: UIImageView!
	@IBOutlet var labelInitials: UILabel!
	@IBOutlet var labelName: UILabel!

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func bindData(person: Person) {

		labelName.text = person.fullname
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func loadImage(person: Person, tableView: UITableView, indexPath: IndexPath) {

		if let path = MediaDownload.pathUser(person.objectId) {
			imageUser.image = UIImage.image(path, size: 40)
			labelInitials.text = nil
		} else {
			imageUser.image = nil
			labelInitials.text = person.initials()
			downloadImage(person: person, tableView: tableView, indexPath: indexPath)
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func downloadImage(person: Person, tableView: UITableView, indexPath: IndexPath) {

		MediaDownload.startUser(person.objectId, pictureAt: person.pictureAt) { image, error in
			let indexSelf = tableView.indexPath(for: self)
			if ((indexSelf == nil) || (indexSelf == indexPath)) {
				if (error == nil) {
					self.imageUser.image = image?.square(to: 40)
					self.labelInitials.text = nil
				} else if (error!.code() == 102) {
					DispatchQueue.main.async(after: 0.5) {
						self.downloadImage(person: person, tableView: tableView, indexPath: indexPath)
					}
				}
			}
		}
	}
}
