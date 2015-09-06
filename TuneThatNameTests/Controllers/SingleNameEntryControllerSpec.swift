import TuneThatName
import Quick
import Nimble

class SingleNameEntryControllerSpec: QuickSpec {
    
    var completionHandlerContact: Contact?
    
    func singleNameEntryCompletionHandler(contact: Contact) {
        completionHandlerContact = contact
    }
    
    override func spec() {
        var singleNameEntryController: SingleNameEntryController!
        
        beforeEach() {
            singleNameEntryController = SingleNameEntryController(completionHandler: self.singleNameEntryCompletionHandler)
        }
        
        describe("NameSearchEntryController") {
            it("has the expected title") {
                expect(singleNameEntryController.title).to(equal("Choose a Name"))
            }
        }
    }
}
