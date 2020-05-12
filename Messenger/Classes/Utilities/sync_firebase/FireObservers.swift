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

import FirebaseFirestore

//-------------------------------------------------------------------------------------------------------------------------------------------------
class FireObservers: NSObject {

	private var observerPerson:		FireObserver?
	private var observerFriend:		FireObserver?
	private var observerBlocked:	FireObserver?
	private var observerBlocker:	FireObserver?
	private var observerSingle1:	FireObserver?
	private var observerSingle2:	FireObserver?
	private var observerMember:		FireObserver?

	private var observerMembers:	[String: FireObserver] = [:]
	private var observerGroups:		[String: FireObserver] = [:]
	private var observerDetails:	[String: FireObserver] = [:]
	private var observerMessages:	[String: FireObserver] = [:]

	//---------------------------------------------------------------------------------------------------------------------------------------------
	static let shared: FireObservers = {
		let instance = FireObservers()
		return instance
	} ()

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override init() {

		super.init()

		NotificationCenter.addObserver(target: self, selector: #selector(initObservers), name: NOTIFICATION_APP_STARTED)
		NotificationCenter.addObserver(target: self, selector: #selector(initObservers), name: NOTIFICATION_USER_LOGGED_IN)
		NotificationCenter.addObserver(target: self, selector: #selector(stopObservers), name: NOTIFICATION_USER_LOGGED_OUT)
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc private func initObservers() {

		if (AuthUser.userId() != "") {
			if (observerPerson == nil)	{ createObserverPerson()	}
			if (observerFriend == nil)	{ createObserverFriend()	}
			if (observerBlocked == nil)	{ createObserverBlocked()	}
			if (observerBlocker == nil)	{ createObserverBlocker()	}
			if (observerSingle1 == nil)	{ createObserverSingle1()	}
			if (observerSingle2 == nil)	{ createObserverSingle2()	}
			if (observerMember == nil)	{ createObserverMember()	}
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc private func stopObservers() {

		observerPerson?.removeObserver();	observerPerson = nil
		observerFriend?.removeObserver();	observerFriend = nil
		observerBlocked?.removeObserver();	observerBlocked = nil
		observerBlocker?.removeObserver();	observerBlocker = nil
		observerSingle1?.removeObserver();	observerSingle1 = nil
		observerSingle2?.removeObserver();	observerSingle2 = nil
		observerMember?.removeObserver();	observerMember = nil

		for chatId in observerMembers.keys	{ observerMembers[chatId]?.removeObserver()	 }
		for chatId in observerGroups.keys	{ observerGroups[chatId]?.removeObserver()	 }
		for chatId in observerDetails.keys	{ observerDetails[chatId]?.removeObserver()	 }
		for chatId in observerMessages.keys	{ observerMessages[chatId]?.removeObserver() }

		observerMembers.removeAll()
		observerGroups.removeAll()
		observerDetails.removeAll()
		observerMessages.removeAll()
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func createObserverPerson() {

		let query = Firestore.firestore().collection("Person")
			.whereField("updatedAt", isGreaterThan: Person.lastUpdatedAt())
		observerPerson = FireObserver(query, to: Person.self)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func createObserverFriend() {

		let query = Firestore.firestore().collection("Friend")
			.whereField("userId", isEqualTo: AuthUser.userId())
		observerFriend = FireObserver(query, to: Friend.self)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func createObserverBlocked() {

		let query = Firestore.firestore().collection("Blocked")
			.whereField("blockedId", isEqualTo: AuthUser.userId())
		observerBlocked = FireObserver(query, to: Blocked.self)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func createObserverBlocker() {

		let query = Firestore.firestore().collection("Blocked")
			.whereField("blockerId", isEqualTo: AuthUser.userId())
		observerBlocker = FireObserver(query, to: Blocked.self)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func createObserverSingle1() {

		let query = Firestore.firestore().collection("Single")
			.whereField("userId1", isEqualTo: AuthUser.userId())
		observerSingle1 = FireObserver(query, to: Single.self)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func createObserverSingle2() {

		let query = Firestore.firestore().collection("Single")
			.whereField("userId2", isEqualTo: AuthUser.userId())
		observerSingle2 = FireObserver(query, to: Single.self)
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func createObserverMember() {

		let query = Firestore.firestore().collection("Member")
			.whereField("userId", isEqualTo: AuthUser.userId())
		observerMember = FireObserver(query, to: Member.self) { insert, modify in
			if (insert) {
				if let chatIds = Members.chatIds() {
					self.createObserverMembers(chatIds)
					self.createObserverGroup(chatIds)
					self.createObserverDetail(chatIds)
					self.createObserverMessage(chatIds)
				}
			}
		}
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func createObserverMembers(_ chatIds: [String]) {

		for chatId in chatIds {
			if (observerMembers[chatId] == nil) {
				let query = Firestore.firestore().collection("Member").whereField("chatId", isEqualTo: chatId)
				observerMembers[chatId] = FireObserver(query, to: Member.self)
			}
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func createObserverGroup(_ chatIds: [String]) {

		for chatId in chatIds {
			if (observerGroups[chatId] == nil) {
				let query = Firestore.firestore().collection("Group").whereField("chatId", isEqualTo: chatId)
				observerGroups[chatId] = FireObserver(query, to: Group.self)
			}
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func createObserverDetail(_ chatIds: [String]) {

		for chatId in chatIds {
			if (observerDetails[chatId] == nil) {
				let query = Firestore.firestore().collection("Detail").whereField("chatId", isEqualTo: chatId)
				observerDetails[chatId] = FireObserver(query, to: Detail.self)
			}
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func createObserverMessage(_ chatIds: [String]) {

		for chatId in chatIds {
			if (observerMessages[chatId] == nil) {
				let query = Firestore.firestore().collection("Message").whereField("chatId", isEqualTo: chatId)
					.whereField("updatedAt", isGreaterThan: Message.lastUpdatedAt(chatId))
				observerMessages[chatId] = FireObserver(query, to: Message.self)
			}
		}
	}
}
