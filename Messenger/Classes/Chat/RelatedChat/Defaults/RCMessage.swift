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
import CoreLocation

//-------------------------------------------------------------------------------------------------------------------------------------------------
class RCMessage: NSObject {

	var chatId: String = ""
	var messageId: String = ""

	var userId: String = ""
	var userFullname: String = ""
	var userInitials: String = ""
	var userPictureAt: Int64 = 0

	var type: String = ""
	var text: String = ""

	var photoWidth: Int = 0
	var photoHeight: Int = 0
	var videoDuration: Int = 0
	var audioDuration: Int = 0

	var latitude: CLLocationDegrees = 0
	var longitude: CLLocationDegrees = 0

	var isMediaQueued = false
	var isMediaFailed = false

	var createdAt: Int64 = 0

	var incoming: Bool = false
	var outgoing: Bool = false

	var videoPath: String = ""
	var audioPath: String = ""

	var photoImage: UIImage?
	var videoThumbnail: UIImage?
	var locationThumbnail: UIImage?

	var audioStatus: Int32 = AUDIOSTATUS_STOPPED
	var mediaStatus: Int32 = MEDIASTATUS_UNKNOWN

	// MARK: - Initialization methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	override init() {

		super.init()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	init(message: Message) {

		super.init()

		self.chatId = message.chatId
		self.messageId = message.objectId

		self.userId = message.userId
		self.userFullname = message.userFullname
		self.userInitials = message.userInitials
		self.userPictureAt = message.userPictureAt

		self.type = message.type
		self.text = message.text

		self.photoWidth = message.photoWidth
		self.photoHeight = message.photoHeight
		self.videoDuration = message.videoDuration
		self.audioDuration = message.audioDuration

		self.latitude = message.latitude
		self.longitude = message.longitude

		self.isMediaQueued = message.isMediaQueued
		self.isMediaFailed = message.isMediaFailed

		self.createdAt = message.createdAt

		let currentId = AuthUser.userId()
		self.incoming = (message.userId != currentId)
		self.outgoing = (message.userId == currentId)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func update(_ message: Message) {

		self.isMediaQueued = message.isMediaQueued
		self.isMediaFailed = message.isMediaFailed
	}
}
