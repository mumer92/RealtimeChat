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
class AllMediaCell: UICollectionViewCell {

	@IBOutlet var imageItem: UIImageView!
	@IBOutlet var imageVideo: UIImageView!

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func bindData(message: Message) {

		imageItem.image = nil

		if (message.type == MESSAGE_PHOTO) {
			bindPicture(message: message)
		}
		if (message.type == MESSAGE_VIDEO) {
			bindVideo(message: message)
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func bindPicture(message: Message) {

		imageVideo.isHidden = true

		if let path = MediaDownload.pathPhoto(message.objectId) {
			imageItem.image = UIImage.image(path, size: 160)
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func bindVideo(message: Message) {

		imageVideo.isHidden = false

		if let path = MediaDownload.pathVideo(message.objectId) {
			DispatchQueue(label: "bindVideo").async {
				let thumbnail = Video.thumbnail(path: path)
				DispatchQueue.main.async {
					self.imageItem.image = thumbnail.square(to: 160)
				}
			}
		}
	}
}
