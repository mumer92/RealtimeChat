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
class FireUpdaters: NSObject {

	private var updaterPerson:	FireUpdater?
	private var updaterFriend:	FireUpdater?
	private var updaterBlocked:	FireUpdater?
	private var updaterMember:	FireUpdater?

	private var updaterGroup:	FireUpdater?
	private var updaterSingle:	FireUpdater?
	private var updaterDetail:	FireUpdater?
	private var updaterMessage:	FireUpdater?

	//---------------------------------------------------------------------------------------------------------------------------------------------
	static let shared: FireUpdaters = {
		let instance = FireUpdaters()
		return instance
	} ()

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override init() {

		super.init()

		updaterPerson	= FireUpdater(name: "Person", type: Person.self)
		updaterFriend	= FireUpdater(name: "Friend", type: Friend.self)
		updaterBlocked	= FireUpdater(name: "Blocked", type: Blocked.self)
		updaterMember	= FireUpdater(name: "Member", type: Member.self)

		updaterGroup	= FireUpdater(name: "Group", type: Group.self)
		updaterSingle	= FireUpdater(name: "Single", type: Single.self)
		updaterDetail	= FireUpdater(name: "Detail", type: Detail.self)
		updaterMessage	= FireUpdater(name: "Message", type: Message.self)
	}
}
