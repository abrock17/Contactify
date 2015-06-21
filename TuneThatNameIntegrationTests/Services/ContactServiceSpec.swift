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
            var addressBookContact: Contact!
            
            beforeEach() {
                self.callbackContactList = nil
                self.callbackError = nil
                contactService = ContactService()
                addressBookContact = self.saveNewContact(firstName: "Casey", lastName: "Kasem")
            }
            
            afterEach() {
                self.deleteContact(addressBookContact)
            }
            
            describe("retrieve all contacts") {
                it("calls back with a list containing an expected contact") {
                    contactService.retrieveAllContacts(self.contactListCallback)
                    
                    let matchingRetrievedContacts = self.callbackContactList?.filter({ $0 == addressBookContact })
                    expect(matchingRetrievedContacts?.count).to(equal(1))
                    let retrievedContact = matchingRetrievedContacts?.first
                    expect(retrievedContact?.id).to(equal(addressBookContact.id))
                    expect(retrievedContact?.firstName).to(equal(addressBookContact.firstName))
                    expect(retrievedContact?.lastName).to(equal(addressBookContact.lastName))
                    expect(retrievedContact?.fullName).to(equal(addressBookContact.fullName))
                }
            }
            
            describe("retrieve filtered contacts") {
                fcontext("when a contact is saved as a filtered contact") {
                    var filteredContact: Contact!
                    beforeEach() {
                        filteredContact = Contact(id: addressBookContact.id, firstName: addressBookContact.firstName, lastName: "Jones")
                        contactService.saveFilteredContacts([filteredContact])
                    }
                    
                    it("calls back with the corresponding contact from the address book") {
                        contactService.retrieveFilteredContacts(self.contactListCallback)

                        let matchingRetrievedContacts = self.callbackContactList?.filter({ $0 == addressBookContact })
                        expect(matchingRetrievedContacts?.count).to(equal(1))
                        let retrievedContact = matchingRetrievedContacts?.first
                        expect(retrievedContact?.id).to(equal(addressBookContact.id))
                        expect(retrievedContact?.firstName).to(equal(addressBookContact.firstName))
                        expect(retrievedContact?.lastName).to(equal(addressBookContact.lastName))
                        expect(retrievedContact?.fullName).to(equal(addressBookContact.fullName))
                    }
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
