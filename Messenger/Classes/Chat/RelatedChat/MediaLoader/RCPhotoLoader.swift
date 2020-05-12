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
class RCPhotoLoader: NSObject {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func start(_ rcmessage: RCMessage, in tableView: UITableView) {

		if let path = MediaDownload.pathPhoto(rcmessage.messageId) {
			showMedia(rcmessage, path: path)
		} else {
			loadMedia(rcmessage, in: tableView)
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func manual(_ rcmessage: RCMessage, in tableView: UITableView) {

		MediaDownload.clearManualPhoto(rcmessage.messageId)
		downloadMedia(rcmessage, in: tableView)
		tableView.reloadData()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private class func loadMedia(_ rcmessage: RCMessage, in tableView: UITableView) {

		let network = Persons.networkPhoto()

		if (network == NETWORK_MANUAL) || ((network == NETWORK_WIFI) && (Connectivity.isReachableViaWiFi() == false)) {
			rcmessage.mediaStatus = MEDIASTATUS_MANUAL
		} else {
			downloadMedia(rcmessage, in: tableView)
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private class func downloadMedia(_ rcmessage: RCMessage, in tableView: UITableView) {

		rcmessage.mediaStatus = MEDIASTATUS_LOADING

		MediaDownload.startPhoto(rcmessage.messageId) { path, error in
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

		rcmessage.photoImage = UIImage(contentsOfFile: path)
		rcmessage.mediaStatus = MEDIASTATUS_SUCCEED
	}
}
