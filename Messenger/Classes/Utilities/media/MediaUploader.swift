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
class MediaUploader: NSObject {

	private var uploading = false

	private var messages = realm.objects(Message.self).filter(falsepredicate)

	//---------------------------------------------------------------------------------------------------------------------------------------------
	static let shared: MediaUploader = {
		let instance = MediaUploader()
		return instance
	} ()

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override init() {

		super.init()

		loadMessages()

		NotificationCenter.addObserver(target: self, selector: #selector(loadMessages), name: NOTIFICATION_USER_LOGGED_IN)
		NotificationCenter.addObserver(target: self, selector: #selector(unloadMessages), name: NOTIFICATION_USER_LOGGED_OUT)

		Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
			if (AuthUser.userId() != "") {
				if (Connectivity.isReachable()) {
					self.uploadNextMedia()
				}
			}
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc private func loadMessages() {

		if (AuthUser.userId() != "") {
			let predicate = NSPredicate(format: "userId == %@ AND isMediaQueued == YES AND isMediaFailed == NO", AuthUser.userId())
			messages = realm.objects(Message.self).filter(predicate).sorted(byKeyPath: "updatedAt")
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc private func unloadMessages() {

		messages = realm.objects(Message.self).filter(falsepredicate)
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func uploadNextMedia() {

		if (uploading) { return }

		if let message = messages.first {
			upload(message: message) { error in
				if (error == nil) {
					message.update(isMediaQueued: false)
				} else {
					message.update(isMediaFailed: true)
				}
				self.uploading = false
			}
		}
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func upload(message: Message, completion: @escaping (_ error: Error?) -> Void) {

		uploading = true

		if (message.type == MESSAGE_PHOTO) { uploadPhoto(message: message, completion: completion) }
		if (message.type == MESSAGE_VIDEO) { uploadVideo(message: message, completion: completion) }
		if (message.type == MESSAGE_AUDIO) { uploadAudio(message: message, completion: completion) }
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func uploadPhoto(message: Message, completion: @escaping (_ error: Error?) -> Void) {

		if let path = MediaDownload.pathPhoto(message.objectId) {
			if let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
				if let crypted = Cryptor.encrypt(data: data, chatId: message.chatId) {
					MediaUpload.photo(message.objectId, data: crypted, completion: { error in
						completion(error)
					})
				} else { completion(NSError.description("Media encryption error.", code: 101)) }
			} else { completion(NSError.description("Media file error.", code: 102)) }
		} else { completion(NSError.description("Missing media file.", code: 103)) }
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func uploadVideo(message: Message, completion: @escaping (_ error: Error?) -> Void) {

		if let path = MediaDownload.pathVideo(message.objectId) {
			if let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
				if let crypted = Cryptor.encrypt(data: data, chatId: message.chatId) {
					MediaUpload.video(message.objectId, data: crypted, completion: { error in
						completion(error)
					})
				} else { completion(NSError.description("Media encryption error.", code: 101)) }
			} else { completion(NSError.description("Media file error.", code: 102)) }
		} else { completion(NSError.description("Missing media file.", code: 103)) }
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func uploadAudio(message: Message, completion: @escaping (_ error: Error?) -> Void) {

		if let path = MediaDownload.pathAudio(message.objectId) {
			if let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
				if let crypted = Cryptor.encrypt(data: data, chatId: message.chatId) {
					MediaUpload.audio(message.objectId, data: crypted, completion: { error in
						completion(error)
					})
				} else { completion(NSError.description("Media encryption error.", code: 101)) }
			} else { completion(NSError.description("Media file error.", code: 102)) }
		} else { completion(NSError.description("Missing media file.", code: 103)) }
	}
}
