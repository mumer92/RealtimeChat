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

import Foundation

//-------------------------------------------------------------------------------------------------------------------------------------------------
class MediaUpload: NSObject {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func user(_ name: String, data: Data, completion: @escaping (_ error: Error?) -> Void) {

		FireStorage.upload(data: data, dir: "user", name: name, ext: "jpg", completion: completion)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func photo(_ name: String, data: Data, completion: @escaping (_ error: Error?) -> Void) {

		FireStorage.upload(data: data, dir: "media", name: name, ext: "jpg", completion: completion)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func video(_ name: String, data: Data, completion: @escaping (_ error: Error?) -> Void) {

		FireStorage.upload(data: data, dir: "media", name: name, ext: "mp4", completion: completion)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func audio(_ name: String, data: Data, completion: @escaping (_ error: Error?) -> Void) {

		FireStorage.upload(data: data, dir: "media", name: name, ext: "m4a", completion: completion)
	}
}
