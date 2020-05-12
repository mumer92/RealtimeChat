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
class AllMediaView: UIViewController {

	@IBOutlet var collectionView: UICollectionView!

	private var chatId = ""
	private var messages_media: [Message] = []

	//---------------------------------------------------------------------------------------------------------------------------------------------
	init(chatId: String) {

		super.init(nibName: nil, bundle: nil)

		self.chatId = chatId
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	required init?(coder aDecoder: NSCoder) {

		super.init(coder: aDecoder)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func viewDidLoad() {

		super.viewDidLoad()
		title = "All Media"

		collectionView.register(UINib(nibName: "AllMediaCell", bundle: nil), forCellWithReuseIdentifier: "AllMediaCell")

		loadMedia()
	}

	// MARK: - Load methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func loadMedia() {

		let predicate = NSPredicate(format: "chatId == %@ AND isDeleted == NO", chatId)
		let messages = realm.objects(Message.self).filter(predicate).sorted(byKeyPath: "createdAt")

		for message in messages {
			if (message.type == MESSAGE_PHOTO) {
				if (MediaDownload.pathPhoto(message.objectId) != nil) {
					messages_media.append(message)
				}
			}
			if (message.type == MESSAGE_VIDEO) {
				if (MediaDownload.pathVideo(message.objectId) != nil) {
					messages_media.append(message)
				}
			}
		}

		collectionView.reloadData()
	}

	// MARK: - User actions
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func presentPicture(message: Message) {

		if (MediaDownload.pathPhoto(message.objectId) != nil) {
			let pictureView = PictureView(chatId: chatId, messageId: message.objectId)
			present(pictureView, animated: true)
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func presentVideo(message: Message) {

		if let path = MediaDownload.pathVideo(message.objectId) {
			let url = URL(fileURLWithPath: path)
			let videoView = VideoView(url: url)
			present(videoView, animated: true)
		}
	}
}

// MARK: - UICollectionViewDataSource
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension AllMediaView: UICollectionViewDataSource {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func numberOfSections(in collectionView: UICollectionView) -> Int {

		return 1
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

		return messages_media.count
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AllMediaCell", for: indexPath) as! AllMediaCell

		let message = messages_media[indexPath.item]
		cell.bindData(message: message)

		return cell
	}
}

// MARK: - UICollectionViewDelegateFlowLayout
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension AllMediaView: UICollectionViewDelegateFlowLayout {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

		let screenWidth = UIScreen.main.bounds.size.width
		return CGSize(width: screenWidth/2, height: screenWidth/2)
	}
}

// MARK: - UICollectionViewDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension AllMediaView: UICollectionViewDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

		collectionView.deselectItem(at: indexPath, animated: true)

		let message = messages_media[indexPath.item]

		if (message.type == MESSAGE_PHOTO) {
			presentPicture(message: message)
		}
		if (message.type == MESSAGE_VIDEO) {
			presentVideo(message: message)
		}
	}
}
