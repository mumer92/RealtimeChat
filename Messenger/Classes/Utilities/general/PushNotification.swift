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

import OneSignal

//-------------------------------------------------------------------------------------------------------------------------------------------------
class PushNotification: NSObject {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func oneSignalId() -> String {

		if let status = OneSignal.getPermissionSubscriptionState() {
			if (status.subscriptionStatus.pushToken != nil) {
				if let userId = status.subscriptionStatus.userId {
					return userId
				}
			}
		}
		return ""
	}

	// MARK: -
	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func send(message: Message) {

		let type = message.type
		var text = message.userFullname

		if (type == MESSAGE_TEXT)		{ text = text + (" sent you a text message.")	}
		if (type == MESSAGE_EMOJI)		{ text = text + (" sent you an emoji.")			}
		if (type == MESSAGE_PHOTO)		{ text = text + (" sent you a photo.")			}
		if (type == MESSAGE_VIDEO)		{ text = text + (" sent you a video.")			}
		if (type == MESSAGE_AUDIO) 		{ text = text + (" sent you an audio.")			}
		if (type == MESSAGE_LOCATION)	{ text = text + (" sent you a location.")		}

		let chatId = message.chatId
		var userIds = Members.userIds(chatId: chatId)

		let predicate = NSPredicate(format: "chatId == %@", chatId)
		for detail in realm.objects(Detail.self).filter(predicate) {
			if (detail.mutedUntil > Date().timestamp()) {
				userIds.removeObject(detail.userId)
			}
		}
		userIds.removeObject(AuthUser.userId())

		send(userIds: userIds, text: text)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private class func send(userIds: [String], text: String) {

		let predicate = NSPredicate(format: "objectId IN %@", userIds)
		let persons = realm.objects(Person.self).filter(predicate).sorted(byKeyPath: "fullname")

		var oneSignalIds: [String] = []

		for person in persons {
			if (person.oneSignalId.count != 0) {
				oneSignalIds.append(person.oneSignalId)
			}
		}

		OneSignal.postNotification(["contents": ["en": text], "include_player_ids": oneSignalIds])
	}
}
