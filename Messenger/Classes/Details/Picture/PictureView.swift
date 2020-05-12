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

import NYTPhotoViewer

//-------------------------------------------------------------------------------------------------------------------------------------------------
class PictureView: NYTPhotosViewController {

	private var photoDataSource: NYTPhotoSource!
	private var isShareButtonVisible = false

	//---------------------------------------------------------------------------------------------------------------------------------------------
	convenience init(image: UIImage, isShareButtonVisible: Bool = false) {

		let photoItem = NYTPhotoItem(image: image)
		let dataSource = NYTPhotoSource(photoItems: [photoItem])
		self.init(dataSource: dataSource, initialPhoto: nil, delegate: nil)

		self.photoDataSource = dataSource
		self.isShareButtonVisible = isShareButtonVisible
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	convenience init(chatId: String, messageId: String, isShareButtonVisible: Bool = true) {

		var photoItems: [NYTPhotoItem] = []
		var initialPhoto: NYTPhotoItem? = nil

		let predicate = NSPredicate(format: "chatId == %@ AND type == %@ AND isDeleted == NO", chatId, MESSAGE_PHOTO)
		let messages = realm.objects(Message.self).filter(predicate).sorted(byKeyPath: "createdAt")

		let attributesTitle = [NSAttributedString.Key.foregroundColor: UIColor.white,
							   NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .body)]
		let attributesCredit = [NSAttributedString.Key.foregroundColor: UIColor.gray,
								NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)]

		for message in messages {
			if let path = MediaDownload.pathPhoto(message.objectId) {
				let title = message.userFullname
				let credit = Convert.timestampToDayMonthTime(message.createdAt)

				let photoItem = NYTPhotoItem()
				photoItem.image = UIImage(contentsOfFile: path)
				photoItem.attributedCaptionTitle = NSAttributedString(string: title, attributes: attributesTitle)
				photoItem.attributedCaptionCredit = NSAttributedString(string: credit, attributes: attributesCredit)
				photoItem.objectId = message.objectId

				if (message.objectId == messageId) {
					initialPhoto = photoItem
				}
				photoItems.append(photoItem)
			}
		}

		if (initialPhoto == nil) { initialPhoto = photoItems.first }

		let dataSource = NYTPhotoSource(photoItems: photoItems)
		self.init(dataSource: dataSource, initialPhoto: initialPhoto, delegate: nil)

		self.photoDataSource = dataSource
		self.isShareButtonVisible = isShareButtonVisible
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func viewDidLoad() {

		super.viewDidLoad()

		if (isShareButtonVisible) {
			rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(actionShare))
		} else {
			rightBarButtonItem = nil
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override var prefersStatusBarHidden: Bool {

		return false
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override var preferredStatusBarStyle: UIStatusBarStyle {

		return .lightContent
	}

	// MARK: - User actions
	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc func actionShare() {

		if let photoItem = currentlyDisplayedPhoto as? NYTPhotoItem {
			if let image = photoItem.image {
				let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
				present(activityViewController, animated: true)
			}
		}
	}
}
