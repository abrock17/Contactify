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
                playlistNameEntryController = PlaylistNameEntryController(currentName: nil, completionHandler: self.playlistNameEntryCompletionHandler)
                it("the OK action is disabled") {
                    expect(playlistNameEntryController.actions.last?.enabled).to(beFalse())
                }
                
                context("and text is entered") {
                    let textField = playlistNameEntryController.textFields!.first!
                    it("enables the OK action") {
                        textField.text = "x"
                        textField.sendActionsForControlEvents(UIControlEvents.EditingChanged)

                        expect(playlistNameEntryController.actions.last?.enabled).to(beTrue())
                    }
                    
                    context("and text is cleared") {
                        it("disables the OK action") {
                            textField.text = ""
                            textField.sendActionsForControlEvents(UIControlEvents.EditingChanged)
                            
                            expect(playlistNameEntryController.actions.last?.enabled).to(beFalse())
                        }
                    }
                }
            }

            context("when the name is populated") {
                let playlistName = "i got a name"
                beforeEach() {
                    playlistNameEntryController = PlaylistNameEntryController(currentName: playlistName, completionHandler: self.playlistNameEntryCompletionHandler)
                }
                
                it("the name is set in the text field") {
                    let textField = playlistNameEntryController.textFields!.first!
                    expect(textField.text).to(equal(playlistName))
                }
                
                it("the OK action is enabled") {
                    expect(playlistNameEntryController.actions.last?.enabled).to(beTrue())
                }

                context("and text is cleared") {
                    it("enables the OK action") {
                        let textField = playlistNameEntryController.textFields!.first!
                        textField.text = ""
                        textField.sendActionsForControlEvents(UIControlEvents.EditingChanged)
                        
                        expect(playlistNameEntryController.actions.last?.enabled).to(beFalse())
                    }
                }
            }
        }
    }
}
