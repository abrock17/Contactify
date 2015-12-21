import TuneThatName
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
                addressBookContact = self.saveNewContactWithFirstName("Casey", andLastName: "Kasem")
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
                context("when a contact is saved as a filtered contact") {
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
            
            describe("create a buncha contacts") {
                let lastName = "Smith"
                let firstNames = ["Al", "Bill", "Charlie", "Desmond", "Ernie", "Frank", "George", "Henry",
                    "Icabod", "Jim", "Kevin", "Larry", "Mitch", "Norwin", "Orville", "Paul", "Quincy",
                    "Rod", "Sam", "Terrence", "Ulysses", "Vinnie", "Walter", "Xavier", "Yakov", "Zack"]
                xit("creates em") {
                    for _ in 0..<4 {
                        for firstName in firstNames {
                            self.saveNewContactWithFirstName(firstName, andLastName: lastName)
                        }
                    }
                }
            }
            
            describe("screenshot contacts") {
                let contacts = [
                    Contact(id: 100, firstName: "BJ", lastName: "Armstrong"),
                    Contact(id: 101, firstName: "Michael", lastName: "Jordan"),
                    Contact(id: 102, firstName: "Scottie", lastName: "Pippen"),
                    Contact(id: 103, firstName: "Horace", lastName: "Grant"),
                    Contact(id: 104, firstName: "Bill", lastName: "Cartwright"),
                    Contact(id: 105, firstName: "Stephen", lastName: "Stills"),
                    Contact(id: 106, firstName: "David", lastName: "Crosby"),
                    Contact(id: 107, firstName: "Graham", lastName: "Nash"),
                    Contact(id: 108, firstName: "Neil", lastName: "Young"),
                ]
                xit("creates em") {
                    for contact in contacts {
                        self.saveNewContactWithFirstName(contact.firstName!, andLastName: contact.lastName!)
                    }
                }
            }
        }
    }
    
    func saveNewContactWithFirstName(firstName: String, andLastName lastName: String) -> Contact {
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
