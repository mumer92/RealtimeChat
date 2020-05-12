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
class RCVideoLoader: NSObject {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func start(_ rcmessage: RCMessage, in tableView: UITableView) {

		if let path = MediaDownload.pathVideo(rcmessage.messageId) {
			showMedia(rcmessage, path: path)
		} else {
			loadMedia(rcmessage, in: tableView)
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func manual(_ rcmessage: RCMessage, in tableView: UITableView) {

		MediaDownload.clearManualVideo(rcmessage.messageId)
		downloadMedia(rcmessage, in: tableView)
		tableView.reloadData()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private class func loadMedia(_ rcmessage: RCMessage, in tableView: UITableView) {

		let network = Persons.networkVideo()

		if (network == NETWORK_MANUAL) || ((network == NETWORK_WIFI) && (Connectivity.isReachableViaWiFi() == false)) {
			rcmessage.mediaStatus = MEDIASTATUS_MANUAL
		} else {
			downloadMedia(rcmessage, in: tableView)
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private class func downloadMedia(_ rcmessage: RCMessage, in tableView: UITableView) {

		rcmessage.mediaStatus = MEDIASTATUS_LOADING

		MediaDownload.startVideo(rcmessage.messageId) { path, error in
			if (error == nil) {
				Cryptor.decrypt(path: path, chatId: rcmessage.chatId)
				showMedia(rcmessage, path: path)
			} else {
				rcmessage.mediaStatus = MEDIASTATUS_MANUAL
			}
			tableView.reloadData()
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private class func showMedia(_ rcmessage: RCMessage, path: String) {

		let thumbnail = Video.thumbnail(path: path)

		rcmessage.videoPath = path
		rcmessage.videoThumbnail = thumbnail.square(to: 200)
		rcmessage.mediaStatus = MEDIASTATUS_SUCCEED
	}
}
