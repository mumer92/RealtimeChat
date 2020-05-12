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

import MessageKit
import CoreLocation

//-------------------------------------------------------------------------------------------------------------------------------------------------
struct MKSender: SenderType, Equatable {

	var senderId: String
	var displayName: String
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
class MKPhotoItem: NSObject, MediaItem {

	var url: URL?
	var image: UIImage?
	var placeholderImage: UIImage
	var size: CGSize

	init(width: Int, height: Int) {

		self.placeholderImage = UIImage()
		self.size = CGSize(width: width, height: height)
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
class MKVideoItem: NSObject, MediaItem {

	var url: URL?
	var image: UIImage?
	var placeholderImage: UIImage
	var size: CGSize

	init(duration: Int) {

		self.placeholderImage = UIImage()
		self.size = CGSize(width: 240, height: 240)
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
class MKAudioItem: NSObject, AudioItem {

	var url: URL
	var size: CGSize
	var duration: Float

	init(duration: Int) {

		self.url = URL(fileURLWithPath: "")
		self.size = CGSize(width: 160, height: 35)
		self.duration = Float(duration)
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
class MKLocationItem: NSObject, LocationItem {

	var location: CLLocation
	var size: CGSize

	init(location: CLLocation) {

		self.location = location
		self.size = CGSize(width: 240, height: 240)
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
class MKMessage: NSObject, MessageType {

	var chatId: String
	var messageId: String

	var userId: String
	var userFullname: String
	var userInitials: String
	var userPictureAt: Int64

	var mksender: MKSender

	var type: String
	var kind: MessageKind

	var photoItem: MKPhotoItem?
	var videoItem: MKVideoItem?
	var audioItem: MKAudioItem?
	var locationItem: MKLocationItem?

	var isMediaQueued: Bool
	var isMediaFailed: Bool

	var sentDate: Date

	var incoming: Bool
	var outgoing: Bool

	var mediaStatus: Int32

	var sender: SenderType { return mksender }

	//---------------------------------------------------------------------------------------------------------------------------------------------
	init(message: Message) {

		self.chatId = message.chatId
		self.messageId = message.objectId

		self.userId = message.userId
		self.userFullname = message.userFullname
		self.userInitials = message.userInitials
		self.userPictureAt = message.userPictureAt

		self.mksender = MKSender(senderId: message.userId, displayName: message.userFullname)

		self.type = message.type
		switch message.type {
			case MESSAGE_TEXT:
				self.kind = MessageKind.text(message.text)

			case MESSAGE_EMOJI:
				self.kind = MessageKind.emoji(message.text)

			case MESSAGE_PHOTO:
				let photoItem = MKPhotoItem(width: message.photoWidth, height: message.photoHeight)
				self.kind = MessageKind.photo(photoItem)
				self.photoItem = photoItem

			case MESSAGE_VIDEO:
				let videoItem = MKVideoItem(duration: message.videoDuration)
				self.kind = MessageKind.video(videoItem)
				self.videoItem = videoItem

			case MESSAGE_AUDIO:
				let audioItem = MKAudioItem(duration: message.audioDuration)
				self.kind = MessageKind.audio(audioItem)
				self.audioItem = audioItem

			case MESSAGE_LOCATION:
				let location = CLLocation(latitude: message.latitude, longitude: message.longitude)
				let locationItem = MKLocationItem(location: location)
				self.kind = MessageKind.location(locationItem)
				self.locationItem = locationItem

			default:
				self.kind = MessageKind.text(message.text)
		}

		self.isMediaQueued = message.isMediaQueued
		self.isMediaFailed = message.isMediaFailed

		self.sentDate = Date.date(timestamp: message.createdAt)

		let currentId = AuthUser.userId()
		self.incoming = (message.userId != currentId)
		self.outgoing = (message.userId == currentId)

		self.mediaStatus = MEDIASTATUS_UNKNOWN
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func update(_ message: Message) {

		self.isMediaQueued = message.isMediaQueued
		self.isMediaFailed = message.isMediaFailed
	}
}
