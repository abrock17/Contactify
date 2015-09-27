import TuneThatName
import Quick
import Nimble

class SingleNameEntryControllerSpec: QuickSpec {
    
    override func spec() {
        describe("SingleNameEntryController") {
            var singleNameEntryController: SingleNameEntryController!
            var navigationController: UINavigationController!
            var mockContactService: MockContactService!

            var contactList = [
                Contact(id: 1, firstName: "Johnny", lastName: "Bench", fullName: "Johnny Bench"),
                Contact(id: 2, firstName: "Billy", lastName: "Idol", fullName: "Billy Idol"),
                Contact(id: 3, firstName: "Frankie", lastName: "Avalon", fullName: "Frankie Avalon")
            ]
            let songSelectionCompletionHandler = {
                (song: Song, contact: Contact?) -> () in
            }
            beforeEach() {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                
                navigationController = storyboard.instantiateInitialViewController() as! UINavigationController
                
                singleNameEntryController = storyboard.instantiateViewControllerWithIdentifier("SingleNameEntryController") as!  SingleNameEntryController
                
                singleNameEntryController.songSelectionCompletionHandler = songSelectionCompletionHandler
                mockContactService = MockContactService()
                singleNameEntryController.contactService = mockContactService
                mockContactService.mocker.prepareForCallTo(MockContactService.Method.retrieveAllContacts, returnValue: ContactService.ContactListResult.Success(contactList))

                navigationController.pushViewController(singleNameEntryController, animated: false)
                UIApplication.sharedApplication().keyWindow!.rootViewController = navigationController
                NSRunLoop.mainRunLoop().runUntilDate(NSDate())
            }
            
            describe("view did load") {
                it("retrieves all contacts from the contact service") {
                    expect(mockContactService.mocker.getCallCountFor(
                        MockContactService.Method.retrieveAllContacts)).toEventually(equal(1))
                }
                
                it("disables the done button") {
                    expect(singleNameEntryController.doneButton.enabled).to(beFalse())
                }
            }
            
            describe("name entry text change") {
                context("when the text changes to empty") {
                    it("disables the done button") {
                        self.changeNameEntryTextTo("a", on: singleNameEntryController)
                        
                        self.changeNameEntryTextTo("", on: singleNameEntryController)
                        
                        expect(singleNameEntryController.doneButton.enabled).to(beFalse())
                    }
                }
                
                context("when the text changes to blank") {
                    it("disables the done button") {
                        self.changeNameEntryTextTo("a", on: singleNameEntryController)
                        
                        self.changeNameEntryTextTo("    ", on: singleNameEntryController)
                        
                        expect(singleNameEntryController.doneButton.enabled).to(beFalse())
                    }
                }
                
                context("when the text changes to non-empty") {
                    let firstName = "Horatio"
                    beforeEach() {
                        self.changeNameEntryTextTo("", on: singleNameEntryController)
                        
                        self.changeNameEntryTextTo(firstName, on: singleNameEntryController)
                    }
                    
                    it("enables the done button") {
                        expect(singleNameEntryController.doneButton.enabled).to(beTrue())
                    }
                    
                    it("sets the first name on the contact") {
                        self.pressDoneButton(singleNameEntryController)
                        let spotifySongSelectionTableController = navigationController.topViewController as? SpotifySongSelectionTableController
                        expect(spotifySongSelectionTableController?.searchContact.firstName).to(equal(firstName))
                    }
                }
            }
            
            describe("press done button") {
                let firstName = "Shaniqua"
                beforeEach() {
                    self.changeNameEntryTextTo(firstName, on: singleNameEntryController)
                    
                    self.pressDoneButton(singleNameEntryController)
                }
                
                it("segues to the song selection controller") {
                    expect(navigationController.topViewController)
                        .toEventually(beAnInstanceOf(SpotifySongSelectionTableController))
                }
                
                it("sets the searchContact on the song selection controller") {
                    let spotifySongSelectionTableController = navigationController.topViewController as? SpotifySongSelectionTableController
                    expect(spotifySongSelectionTableController?.searchContact.firstName).to(equal(firstName))
                }
                
                it("passes the song selection completion handler to the song selection controller") {
                    let spotifySongSelectionTableController = navigationController.topViewController as? SpotifySongSelectionTableController
                    expect(spotifySongSelectionTableController?.songSelectionCompletionHandler).toNot(beNil())
                }
            }
        }
    }
    
    func changeNameEntryTextTo(text: String, on singleNameEntryController: SingleNameEntryController) {
        singleNameEntryController.nameEntryTextField.text = text
        singleNameEntryController.nameEntryTextChanged(singleNameEntryController.nameEntryTextField)
    }
    
    
    func pressDoneButton(singleNameEntryController: SingleNameEntryController) {
        UIApplication.sharedApplication().sendAction(singleNameEntryController.doneButton.action,
            to: singleNameEntryController.doneButton.target, from: self, forEvent: nil)
    }
}
