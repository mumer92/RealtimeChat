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
class NetworkView: UIViewController {

	@IBOutlet var tableView: UITableView!
	@IBOutlet var cellManual: UITableViewCell!
	@IBOutlet var cellWiFi: UITableViewCell!
	@IBOutlet var cellAll: UITableViewCell!

	private var mediaType: Int32 = 0
	private var selectedNetwork: Int32 = 0

	//---------------------------------------------------------------------------------------------------------------------------------------------
	init(mediaType: Int32) {

		super.init(nibName: nil, bundle: nil)

		self.mediaType = mediaType
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	required init?(coder aDecoder: NSCoder) {

		super.init(coder: aDecoder)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func viewDidLoad() {

		super.viewDidLoad()

		if (mediaType == MEDIA_PHOTO) { title = "Photo" }
		if (mediaType == MEDIA_VIDEO) { title = "Video" }
		if (mediaType == MEDIA_AUDIO) { title = "Audio" }

		if (mediaType == MEDIA_PHOTO) { selectedNetwork = Persons.networkPhoto() }
		if (mediaType == MEDIA_VIDEO) { selectedNetwork = Persons.networkVideo() }
		if (mediaType == MEDIA_AUDIO) { selectedNetwork = Persons.networkAudio() }

		updateDetails()
	}

	// MARK: - Helper methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func updateDetails() {

		cellManual.accessoryType = (selectedNetwork == NETWORK_MANUAL) ? .checkmark : .none
		cellWiFi.accessoryType	 = (selectedNetwork == NETWORK_WIFI) ? .checkmark : .none
		cellAll.accessoryType	 = (selectedNetwork == NETWORK_ALL) ? .checkmark : .none

		tableView.reloadData()
	}
}

// MARK: - UITableViewDataSource
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension NetworkView: UITableViewDataSource {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func numberOfSections(in tableView: UITableView) -> Int {

		return 1
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

		return 3
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

		if (indexPath.section == 0) && (indexPath.row == 0) { return cellManual	}
		if (indexPath.section == 0) && (indexPath.row == 1) { return cellWiFi	}
		if (indexPath.section == 0) && (indexPath.row == 2) { return cellAll	}

		return UITableViewCell()
	}
}

// MARK: - UITableViewDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension NetworkView: UITableViewDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

		tableView.deselectRow(at: indexPath, animated: true)

		if (indexPath.section == 0) && (indexPath.row == 0) { selectedNetwork = NETWORK_MANUAL	}
		if (indexPath.section == 0) && (indexPath.row == 1) { selectedNetwork = NETWORK_WIFI	}
		if (indexPath.section == 0) && (indexPath.row == 2) { selectedNetwork = NETWORK_ALL		}

		if (mediaType == MEDIA_PHOTO) { Persons.update(networkPhoto: selectedNetwork) }
		if (mediaType == MEDIA_VIDEO) { Persons.update(networkVideo: selectedNetwork) }
		if (mediaType == MEDIA_AUDIO) { Persons.update(networkAudio: selectedNetwork) }

		updateDetails()
	}
}
