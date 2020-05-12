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
class ChatManager: NSObject {

	private var tokenGroups: NotificationToken? = nil
	private var tokenSingles: NotificationToken? = nil
	private var tokenDetails: NotificationToken? = nil
	private var tokenMessages: NotificationToken? = nil

	private var groups	= realm.objects(Group.self).filter(falsepredicate)
	private var singles	= realm.objects(Single.self).filter(falsepredicate)
	private var details	= realm.objects(Detail.self).filter(falsepredicate)
	private var messages = realm.objects(Message.self).filter(falsepredicate)

	//---------------------------------------------------------------------------------------------------------------------------------------------
	static let shared: ChatManager = {
		let instance = ChatManager()
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
			if (tokenGroups == nil)		{ loadGroups() }
			if (tokenSingles == nil)	{ loadSingles() }
			if (tokenDetails == nil)	{ loadDetails() }
			if (tokenMessages == nil)	{ loadMessages() }
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc private func stopObservers() {

		tokenGroups?.invalidate();		tokenGroups = nil
		tokenSingles?.invalidate();		tokenSingles = nil
		tokenDetails?.invalidate();		tokenDetails = nil
		tokenMessages?.invalidate();	tokenMessages = nil

		groups	= realm.objects(Group.self).filter(falsepredicate)
		singles	= realm.objects(Single.self).filter(falsepredicate)
		details	= realm.objects(Detail.self).filter(falsepredicate)
		messages = realm.objects(Message.self).filter(falsepredicate)
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func loadGroups() {

		groups = realm.objects(Group.self)

		tokenGroups?.invalidate()
		groups.safeObserve({ changes in
			switch changes {
				case .update(let results, _, let insert, let modify):
					for index in insert + modify {
						let group = results[index]
						self.update(with: group)
					}
				default: break
			}
		}, completion: { token in
			self.tokenGroups = token
		})
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func loadSingles() {

		singles = realm.objects(Single.self)

		tokenSingles?.invalidate()
		singles.safeObserve({ changes in
			switch changes {
				case .update(let results, _, let insert, let modify):
					for index in insert + modify {
						let single = results[index]
						self.update(with: single)
					}
				default: break
			}
		}, completion: { token in
			self.tokenSingles = token
		})
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func loadDetails() {

		details = realm.objects(Detail.self)

		tokenDetails?.invalidate()
		details.safeObserve({ changes in
			switch changes {
				case .update(let results, _, let insert, let modify):
					for index in insert + modify {
						let detail = results[index]
						self.update(with: detail)
					}
				default: break
			}
		}, completion: { token in
			self.tokenDetails = token
		})
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func loadMessages() {

		messages = realm.objects(Message.self).sorted(byKeyPath: "createdAt", ascending: false)

		tokenMessages?.invalidate()
		messages.safeObserve({ changes in
			switch changes {
				case .update(let results, _, let insert, let modify):
					for index in insert + modify {
						let message = results[index]
						self.update(with: message)
					}
				default: break
			}
		}, completion: { token in
			self.tokenMessages = token
		})
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func update(with group: Group) {

		var temp: [String: Any] = [:]
		temp["objectId"] = group.chatId

		temp["isGroup"]		= true
		temp["isPrivate"]	= false

		temp["details"]		= group.name
		temp["initials"]	= group.name.prefix(1)

		temp["isGroupDeleted"] = group.isDeleted

		let realm = try! Realm()
		try! realm.safeWrite {
			realm.create(Chat.self, value: temp, update: .modified)
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func update(with single: Single) {

		let isRecipient = (single.userId1 != AuthUser.userId())

		var temp: [String: Any] = [:]
		temp["objectId"] = single.chatId

		temp["isGroup"]		= false
		temp["isPrivate"]	= true

		temp["details"]		= isRecipient ? single.fullname1	: single.fullname2
		temp["initials"]	= isRecipient ? single.initials1	: single.initials2

		temp["userId"]		= isRecipient ? single.userId1		: single.userId2
		temp["pictureAt"]	= isRecipient ? single.pictureAt1	: single.pictureAt2

		let realm = try! Realm()
		try! realm.safeWrite {
			realm.create(Chat.self, value: temp, update: .modified)
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func update(with detail: Detail) {

		var temp: [String: Any] = [:]
		temp["objectId"] = detail.chatId

		if (detail.userId == AuthUser.userId()) {
			temp["lastRead"]	= detail.lastRead
			temp["mutedUntil"]	= detail.mutedUntil
			temp["unreadCount"]	= unreadCount(detail.chatId, detail.lastRead)
			temp["isDeleted"]	= detail.isDeleted
			temp["isArchived"]	= detail.isArchived
		}

		if (detail.userId != AuthUser.userId()) {
			let predicate = NSPredicate(format: "chatId == %@ AND userId != %@ AND typing == YES", detail.chatId, AuthUser.userId())
			temp["typing"] = (realm.objects(Detail.self).filter(predicate).count != 0)
		}

		let realm = try! Realm()
		try! realm.safeWrite {
			realm.create(Chat.self, value: temp, update: .modified)
		}
	}

	// MARK: - Update with Message
	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func update(with message: Message) {

		if (!message.isDeleted) {
			update(active: message)
		} else {
			update(deleted: message)
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func update(active message: Message) {

		let chatId = message.chatId

		guard let chat = realm.object(ofType: Chat.self, forPrimaryKey: chatId) else {
			update(chatId, with: message, and: nil)
			return
		}

		if (message.createdAt > chat.lastMessageAt) {
			let unread = unreadCount(chat, message)
			update(chatId, with: message, and: unread)
		} else {
			if let unread = unreadCount(chat, message) {
				update(chatId, with: unread)
			}
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func update(deleted message: Message) {

		let chatId = message.chatId

		guard let chat = realm.object(ofType: Chat.self, forPrimaryKey: chatId) else { return }

		if (message.objectId == chat.lastMessageId) {
			if let message = lastMessage(chatId) {
				let unread = unreadCount(chat, message)
				update(chatId, with: message, and: unread)
			} else {
				clearLastMessage(chatId)
			}
		} else {
			if let unread = unreadCount(chat, message) {
				update(chatId, with: unread)
			}
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func update(_ chatId: String, with message: Message, and unread: Int?) {

		var temp: [String: Any] = [:]
		temp["objectId"] = chatId

		temp["lastMessageId"]	= message.objectId
		temp["lastMessageText"]	= message.text
		temp["lastMessageAt"]	= message.createdAt

		if let unread = unread {
			temp["unreadCount"]	= unread
		}

		let realm = try! Realm()
		try! realm.safeWrite {
			realm.create(Chat.self, value: temp, update: .modified)
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func update(_ chatId: String, with unread: Int) {

		var temp: [String: Any] = [:]
		temp["objectId"] = chatId

		temp["unreadCount"] = unread

		let realm = try! Realm()
		try! realm.safeWrite {
			realm.create(Chat.self, value: temp, update: .modified)
		}
	}

	// MARK: - Last Message methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func lastMessage(_ chatId: String) -> Message? {

		let predicate = NSPredicate(format: "chatId == %@ AND isDeleted == NO", chatId)
		return realm.objects(Message.self).filter(predicate).sorted(byKeyPath: "createdAt").last
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func clearLastMessage(_ chatId: String) {

		var temp: [String: Any] = [:]
		temp["objectId"] = chatId

		temp["lastMessageId"]	= ""
		temp["lastMessageText"]	= ""
		temp["lastMessageAt"]	= 0
		temp["unreadCount"]		= 0

		let realm = try! Realm()
		try! realm.safeWrite {
			realm.create(Chat.self, value: temp, update: .modified)
		}
	}

	// MARK: - Unread counter methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func unreadCount(_ chat: Chat, _ message: Message) -> Int? {

		if (message.userId != AuthUser.userId()) {
			if (message.createdAt > chat.lastRead) {
				return unreadCount(chat.objectId, chat.lastRead)
			}
		}

		return nil
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func unreadCount(_ chatId: String, _ lastRead: Int64) -> Int {

		let format = "chatId == %@ AND userId != %@ AND createdAt > %ld AND isDeleted == NO"
		let predicate = NSPredicate(format: format, chatId, AuthUser.userId(), lastRead)
		return realm.objects(Message.self).filter(predicate).count
	}
}
