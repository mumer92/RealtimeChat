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
class MediaDownload: NSObject {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func startUser(_ name: String, pictureAt: Int64, completion: @escaping (_ image: UIImage?, _ error: Error?) -> Void) {

		if (pictureAt != 0) {
			start(dir: "user", name: name, ext: "jpg", manual: false) { path, error in
				if (error == nil) {
					completion(UIImage(contentsOfFile: path), nil)
				} else {
					completion(nil, error)
				}
			}
		} else {
			completion(nil, NSError.description("Missing picture.", code: 100))
		}
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func startPhoto(_ name: String, completion: @escaping (_ path: String, _ error: Error?) -> Void) {

		start(dir: "media", name: name, ext: "jpg", manual: true, completion: completion)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func startVideo(_ name: String, completion: @escaping (_ path: String, _ error: Error?) -> Void) {

		start(dir: "media", name: name, ext: "mp4", manual: true, completion: completion)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func startAudio(_ name: String, completion: @escaping (_ path: String, _ error: Error?) -> Void) {

		start(dir: "media", name: name, ext: "m4a", manual: true, completion: completion)
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	private class func start(dir: String, name: String, ext: String, manual: Bool,
							 completion: @escaping (_ path: String, _ error: Error?) -> Void) {

		let file = "\(name).\(ext)"
		let path = Dir.document(dir, and: file)

		let fileManual = file + ".manual"
		let pathManual = Dir.document(dir, and: fileManual)

		let fileLoading = file + ".loading"
		let pathLoading = Dir.document(dir, and: fileLoading)

		// Check if file is already downloaded
		//-----------------------------------------------------------------------------------------------------------------------------------------
		if (File.exist(path: path)) {
			completion(path, nil)
			return
		}

		// Check if manual download is required
		//-----------------------------------------------------------------------------------------------------------------------------------------
		if (manual) {
			if (File.exist(path: pathManual)) {
				completion("", NSError.description("Manual download required.", code: 101))
				return
			}
			try? "manual".write(toFile: pathManual, atomically: false, encoding: .utf8)
		}

		// Check if file is currently downloading
		//-----------------------------------------------------------------------------------------------------------------------------------------
		let time = Int(Date().timeIntervalSince1970)

		if (File.exist(path: pathLoading)) {
			if let temp = try? String(contentsOfFile: pathLoading, encoding: .utf8) {
				if let check = Int(temp) {
					if (time - check < 60) {
						completion("", NSError.description("Already downloading.", code: 102))
						return
					}
				}
			}
		}
		try? "\(time)".write(toFile: pathLoading, atomically: false, encoding: .utf8)

		// Download the file
		//-----------------------------------------------------------------------------------------------------------------------------------------
		FireStorage.download(dir: dir, name: name, ext: ext) { path, error in
			File.remove(path: pathLoading)
			DispatchQueue.main.async {
				completion(path, error)
			}
		}
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func pathUser(_ name: String) -> String?	{ return path(dir: "user", name: name, ext: "jpg")	}
	class func pathPhoto(_ name: String) -> String?	{ return path(dir: "media", name: name, ext: "jpg")	}
	class func pathVideo(_ name: String) -> String?	{ return path(dir: "media", name: name, ext: "mp4")	}
	class func pathAudio(_ name: String) -> String?	{ return path(dir: "media", name: name, ext: "m4a")	}
	//---------------------------------------------------------------------------------------------------------------------------------------------

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private class func path(dir: String, name: String, ext: String) -> String? {

		let file = "\(name).\(ext)"
		let path = Dir.document(dir, and: file)

		return File.exist(path: path) ? path : nil
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func clearManualPhoto(_ name: String) { clearManual(dir: "media", name: name, ext: "jpg") }
	class func clearManualVideo(_ name: String) { clearManual(dir: "media", name: name, ext: "mp4") }
	class func clearManualAudio(_ name: String) { clearManual(dir: "media", name: name, ext: "m4a") }
	//---------------------------------------------------------------------------------------------------------------------------------------------

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private class func clearManual(dir: String, name: String, ext: String) {

		let file = "\(name).\(ext)"

		let fileManual = file + ".manual"
		let pathManual = Dir.document(dir, and: fileManual)

		let fileLoading = file + ".loading"
		let pathLoading = Dir.document(dir, and: fileLoading)

		File.remove(path: pathManual)
		File.remove(path: pathLoading)
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func saveUser(_ name: String, data: Data)		{ save(data: data, dir: "user", name: name, ext: "jpg", manual: false)	}
	class func savePhoto(_ name: String, data: Data)	{ save(data: data, dir: "media", name: name, ext: "jpg", manual: true)	}
	class func saveVideo(_ name: String, data: Data)	{ save(data: data, dir: "media", name: name, ext: "mp4", manual: true)	}
	class func saveAudio(_ name: String, data: Data)	{ save(data: data, dir: "media", name: name, ext: "m4a", manual: true)	}
	//---------------------------------------------------------------------------------------------------------------------------------------------

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private class func save(data: Data, dir: String, name: String, ext: String, manual: Bool) {

		let file = "\(name).\(ext)"
		let path = Dir.document(dir, and: file)

		let fileManual = file + ".manual"
		let pathManual = Dir.document(dir, and: fileManual)

		try? data.write(to: URL(fileURLWithPath: path), options: .atomic)

		if (manual) {
			try? "manual".write(toFile: pathManual, atomically: false, encoding: .utf8)
		}
	}
}
