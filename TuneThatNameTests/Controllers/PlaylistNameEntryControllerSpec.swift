import TuneThatName
import Quick
import Nimble

class PlaylistNameEntryControllerSpec: QuickSpec {
    
    var completionHandlerPlaylistName: String?
    
    func playlistNameEntryCompletionHandler(playlistName: String) {
        completionHandlerPlaylistName = playlistName
    }

    override func spec() {
        var playlistNameEntryController: PlaylistNameEntryController!
        
        describe("PlaylistNameEntryController") {
            context("when the name is empty") {
                it("the OK action is disabled") {
                    playlistNameEntryController = PlaylistNameEntryController(currentName: nil, completionHandler: self.playlistNameEntryCompletionHandler)
                    
                    expect((playlistNameEntryController.actions.last as? UIAlertAction)?.enabled).to(beFalse())
                }
                
                context("and text is entered") {
                    it("enables the OK action") {
                        let textField = playlistNameEntryController.textFields!.first as! UITextField
                        textField.text = "x"
                        textField.sendActionsForControlEvents(UIControlEvents.EditingChanged)

                        expect((playlistNameEntryController.actions.last as? UIAlertAction)?.enabled).to(beTrue())
                    }
                }
            }

            context("when the name is populated") {
                let playlistName = "i got a name"
                beforeEach() {
                    playlistNameEntryController = PlaylistNameEntryController(currentName: playlistName, completionHandler: self.playlistNameEntryCompletionHandler)
                }
                
                it("the name is set in the text field") {
                    let textField = playlistNameEntryController.textFields!.first as! UITextField
                    expect(textField.text).to(equal(playlistName))
                }
                
                it("the OK action is enabled") {
                    expect((playlistNameEntryController.actions.last as? UIAlertAction)?.enabled).to(beTrue())
                }

                context("and text is cleared") {
                    it("enables the OK action") {
                        let textField = playlistNameEntryController.textFields!.first as! UITextField
                        textField.text = ""
                        textField.sendActionsForControlEvents(UIControlEvents.EditingChanged)
                        
                        expect((playlistNameEntryController.actions.last as? UIAlertAction)?.enabled).to(beFalse())
                    }
                }
            }
        }
    }
}
