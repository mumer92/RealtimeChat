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

import MessageKit

// MARK: - MessagesViewController
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension MessagesViewController {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc func actionMenuDelete(at indexPath: IndexPath) {

	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc func actionMenuForward(at indexPath: IndexPath) {

	}
}

// MARK: - MessageCollectionViewCell
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension MessageCollectionViewCell {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override open func delete(_ sender: Any?) {

		if let messagesCollectionView = self.superview as? MessagesCollectionView {
			if let messagesViewController = messagesCollectionView.parentViewController as? MessagesViewController {
				if let indexPath = messagesCollectionView.indexPath(for: self) {
					messagesViewController.actionMenuDelete(at: indexPath)
				}
			}
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc func forward(_ sender: Any?) {

		if let messagesCollectionView = self.superview as? MessagesCollectionView {
			if let messagesViewController = messagesCollectionView.parentViewController as? MessagesViewController {
				if let indexPath = messagesCollectionView.indexPath(for: self) {
					messagesViewController.actionMenuForward(at: indexPath)
				}
			}
		}
	}
}
