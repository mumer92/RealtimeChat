<img src="https://relatedcode.com/github/header14.png" width="880">

## OVERVIEW

This is a native iOS Messenger app, with audio/video calls and realtime chat conversations (full offline support).

---

<img src="https://relatedcode.com/screen56/chat03x.png" width="290">.<img src="https://relatedcode.com/screen56/call1x.png" width="290">.<img src="https://relatedcode.com/screen56/chats01x.png" width="290">
<img src="https://relatedcode.com/screen56/settings2.png" width="290">.<img src="https://relatedcode.com/screen56/chats02.png" width="290">.<img src="https://relatedcode.com/screen56/chat07.png" width="290">

---

## NEW FEATURES

- CallKit support for audio and video calls
- Database management is powered by SyncEngine
- Works with [MessageKit](https://github.com/MessageKit/MessageKit) chat user interface
- Uses [InputBarAccessoryView](https://github.com/nathantannar4/InputBarAccessoryView) as chat input bar
- Supports native iOS Dark Mode

<img src="https://relatedcode.com/github/syncengine3.png" width="880">

## ADDITIONAL FEATURES

- Full source code is available for all features
- Video call (in-app video calling over data connection)
- Audio call (in-app audio calling over data connection)
- Message queue (creating new messages while offline)
- User last active (or currently online) status info
- Spotlight search for users
- Media download network settings (Wi-Fi, Cellular or Manual)
- Cache settings for media messages (automatic/manual cleanup)
- Media message re-download option
- Block users
- Forward messages
- Mute push notifications
- Home screen quick actions
- Share media message content

## KEY FEATURES

- Firebase Cloud Firestore backend (full realtime actions)
- Realm Database for local data (full offline availability)
- AES-256 encryption

## FEATURES

- Live chat between multiple devices
- Private chat functionality
- Group chat functionality
- Push notification support
- No backend programming is needed
- Native and easy to customize user interface
- Login with Email
- Sending text messages
- Sending pictures
- Sending videos
- Sending audio messages
- Sending current location
- Sending stickers
- Sending large emojis
- Media file local cache
- Load earlier messages
- Typing indicator
- Message delivery receipt
- Message read receipt
- Save picture messages to device
- Save video messages to device
- Save audio messages to device
- Delete read and unread messages
- Realtime conversation view for ongoing chats
- Archived conversation view for archived chats
- All media view for chat media files
- Picture view for multiple pictures
- Map view for shared locations
- Basic Settings view included
- Basic Profile view for users
- Edit Profile view for changing user details
- Onboarding view on signup
- Wallpaper backgrounds for Chat view
- Privacy Policy view
- Terms of Service view
- Video length limit possibility
- Copy and paste text messages
- Arbitrary message sizes
- Send/Receive sound effects
- Supported devices: iPhone SE - iPhone 11 Pro Max

---

<img src="https://relatedcode.com/screen56/addfriendsx.png" width="290">.<img src="https://relatedcode.com/screen56/chat08x.png" width="290">.<img src="https://relatedcode.com/screen56/stickersx.png" width="290">
<img src="https://relatedcode.com/screen56/settings_cache.png" width="290">.<img src="https://relatedcode.com/screen56/settings_archive1.png" width="290">.<img src="https://relatedcode.com/screen56/chat04.png" width="290">

---

## REQUIREMENTS

- iOS 13.0+

## INSTALLATION

**1.,** Run `pod install` first (the CocoaPods Frameworks and Libraries are not included in the repo). If you haven't used CocoaPods before, you can get started [here](https://guides.cocoapods.org/using/getting-started.html). You might prefer to use the [CocoaPods app](https://cocoapods.org/app) over the command-line tool.

**2.,** Create an account at [Firebase](https://firebase.google.com) and create a new project for your application.

**3.,** Set up your Firebase [Authentication](https://firebase.google.com/docs/auth) sign-in methods.

**4.,** Enable your Firebase [Cloud Firestore](https://firebase.google.com/docs/firestore) by updating the Database Rules with the default values.

**5.,** Create an Index with [these settings](https://github.com/relatedcode/Messenger/issues/165).

**6.,** Enable your Firebase [Storage](https://firebase.google.com/docs/storage) by updating the Storage Rules with the default values.

**7.,** Download `GoogleService-Info.plist` from your Firebase project and replace the existing file in your Xcode project.

**8.,** For using push notification feature, create an account at [OneSignal](https://onesignal.com) and replace the `ONESIGNAL_APPID` define value in `AppConstant.h`. You will also need to [configure](https://documentation.onesignal.com/docs/generate-an-ios-push-certificate) your Push certificate details.

**9.,** For using audio and video call features, create an account at [Sinch](https://www.sinch.com) and replace the `SINCH_KEY` and `SINCH_SECRET` define values in `AppConstant.h`. You will also need to [configure](https://developers.sinch.com/docs/how-to-use-pushkit-for-ios-voip-push-notifications) your VoIP certificate details.

---

<img src="https://relatedcode.com/screen56/profile2.png" width="290">.<img src="https://relatedcode.com/screen56/people.png" width="290">.<img src="https://relatedcode.com/screen56/chat06.png" width="290">
<img src="https://relatedcode.com/screen56/chat05x.png" width="290">.<img src="https://relatedcode.com/screen56/settings1x.png" width="290">.<img src="https://relatedcode.com/screen56/chats03x.png" width="290">

---

## CONTACT

Do you have any questions or an idea? My email is info@relatedcode.com or you can find some more info at [relatedcode.com](https://relatedcode.com)

## LICENSE

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

---

<img src="https://relatedcode.com/screen56/chat01.png" width="290">.<img src="https://relatedcode.com/screen56/call2.png" width="290">.<img src="https://relatedcode.com/screen56/profile1.png" width="290">
<img src="https://relatedcode.com/screen56/allmediax.png" width="290">.<img src="https://relatedcode.com/screen56/picture1.png" width="290">.<img src="https://relatedcode.com/screen56/settings_status1x.png" width="290">
