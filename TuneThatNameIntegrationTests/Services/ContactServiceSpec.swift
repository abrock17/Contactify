import TuneThatName
import Foundation
import AddressBook
import Quick
import Nimble

class ContactServiceSpec: QuickSpec {
    
    var callbackContactList: [Contact]?
    var callbackError: NSError?
    
    func contactListCallback(contactListResult: ContactService.ContactListResult) {
        switch (contactListResult) {
        case .Success(let contactList):
            callbackContactList = contactList
        case .Failure(let error):
            callbackError = error
        }
    }
    
    override func spec() {
        describe("The Contact Service") {
            var contactService: ContactService!
            
            beforeEach() {
                self.callbackContactList = nil
                self.callbackError = nil
                contactService = ContactService()
            }
            
            describe("retrieve all contacts") {
                it("calls back with a list containing an expected contact") {
                    
                    contactService.retrieveAllContacts(self.contactListCallback)
                    
                    expect(self.callbackContactList).toEventually(contain(Contact(id: 3, firstName: "John", lastName: "Appleseed")))
                    expect(self.callbackError).to(beNil())
                }
            }
        }
    }
}
