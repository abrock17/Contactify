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
            var contact: Contact!
            
            beforeEach() {
                self.callbackContactList = nil
                self.callbackError = nil
                contactService = ContactService()
                contact = self.saveNewContact(firstName: "Casey", lastName: "Kasem")
            }
            
            afterEach() {
                self.deleteContact(contact)
            }
            
            describe("retrieve all contacts") {
                it("calls back with a list containing an expected contact") {
                    
                    contactService.retrieveAllContacts(self.contactListCallback)
                    
                    expect(self.callbackContactList).toEventually(contain(contact))
                    expect(self.callbackError).to(beNil())
                    expect(contact.fullName).to(equal("Casey Kasem"))
                }
            }
        }
    }
    
    func saveNewContact(#firstName: String, lastName: String) -> Contact {
        let addressBook: ABAddressBookRef! = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()

        let record: ABRecordRef! = ABPersonCreate().takeUnretainedValue()
        ABRecordSetValue(record, kABPersonFirstNameProperty, firstName, nil)
        ABRecordSetValue(record, kABPersonLastNameProperty, lastName, nil)
        
        ABAddressBookAddRecord(addressBook, record, nil)
        ABAddressBookSave(addressBook, nil)
        let fullName = ABRecordCopyCompositeName(record).takeRetainedValue() as String

        return Contact(id: ABRecordGetRecordID(record), firstName: firstName, lastName: lastName, fullName: fullName)
    }
    
    func deleteContact(contact: Contact) {
        let addressBook: ABAddressBookRef! = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()
        let record: ABRecordRef! = ABAddressBookGetPersonWithRecordID(addressBook, contact.id)?.takeUnretainedValue()
        
        ABAddressBookRemoveRecord(addressBook, record, nil)
        ABAddressBookSave(addressBook, nil)
    }
}
