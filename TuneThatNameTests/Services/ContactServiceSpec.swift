import TuneThatName
import Foundation
import AddressBook
import Quick
import Nimble

class ContactServiceSpec: QuickSpec {
    
    let expectedNoAccessError = NSError(domain: Constants.Error.Domain, code: Constants.Error.AddressBookNoAccessCode, userInfo: [NSLocalizedDescriptionKey: Constants.Error.AddressBookNoAccessMessage])
    
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
            var mockAddressBook: MockAddressBookWrapper!
            
            beforeEach() {
                self.callbackContactList = nil
                self.callbackError = nil
                mockAddressBook = MockAddressBookWrapper()
                contactService = ContactService(addressBook: mockAddressBook)
            }
            
            describe("retrieve all contacts") {
                context("when access to the address book is denied") {
                    it("calls back with the expected error") {
                        mockAddressBook.mocker.prepareForCallTo(MockAddressBookWrapper.Method.AddressBookGetAuthorizationStatus, returnValue: ABAuthorizationStatus.Denied)
                        
                        contactService.retrieveAllContacts(self.contactListCallback)
                        
                        expect(self.callbackError).toEventually(equal(self.expectedNoAccessError))
                        expect(self.callbackContactList).to(beNil())
                    }
                }
                
                context("when access to the address book is restricted") {
                    it("calls back with an error") {
                        mockAddressBook.mocker.prepareForCallTo(MockAddressBookWrapper.Method.AddressBookGetAuthorizationStatus, returnValue: ABAuthorizationStatus.Restricted)
                        
                        contactService.retrieveAllContacts(self.contactListCallback)
                        
                        expect(self.callbackError).toEventually(equal(self.expectedNoAccessError))
                        expect(self.callbackContactList).to(beNil())
                    }
                }
                
                context("when authorized to access the address book") {
                    it("calls back with a list of expected contacts") {
                        mockAddressBook.mocker.prepareForCallTo(MockAddressBookWrapper.Method.AddressBookGetAuthorizationStatus, returnValue: ABAuthorizationStatus.Authorized)

                        let expectedContactList = [Contact(id: 1, firstName: "billy", lastName: "johnson"), Contact(id: 2, firstName: "johnny", lastName: "billson")]
                        self.prepareMockAddressBook(mockAddressBook, withExpectedContactList: expectedContactList)
                        
                        contactService.retrieveAllContacts(self.contactListCallback)

                        expect(self.callbackContactList).toEventually(equal(expectedContactList))
                        expect(self.callbackError).to(beNil())
                    }
                }
                
                context("when the application's access to the address book has not been determined") {
                    it("prompts the user for access") {
                        mockAddressBook.mocker.prepareForCallTo(MockAddressBookWrapper.Method.AddressBookGetAuthorizationStatus, returnValue: ABAuthorizationStatus.NotDetermined)
                        
                        contactService.retrieveAllContacts(self.contactListCallback)

                        expect(mockAddressBook.mocker.verifyNthCallTo(MockAddressBookWrapper.Method.AddressBookRequestAccessWithCompletion, n: 0)).toNot(beNil())
                        expect(mockAddressBook.mocker.verifyNthCallTo(MockAddressBookWrapper.Method.AddressBookRequestAccessWithCompletion, n: 0)).to(beEmpty())
                    }
                    
                    context("and access is not granted") {
                        it("calls back with an error") {
                            
                        }
                    }
                    
                    context("and access is granted") {
                        it("calls back with a list of expected contacts") {

                        }
                    }
                }
            }
        }
    }
    
    func prepareMockAddressBook(mockAddressBook: MockAddressBookWrapper, withExpectedContactList contactList: [Contact]) {
        var ids = [AnyObject]()
        
        for contact in contactList {
            mockAddressBook.mocker.prepareForCallTo(MockAddressBookWrapper.Method.RecordGetRecordID, returnValue: contact.id)
            mockAddressBook.mocker.prepareForCallTo(MockAddressBookWrapper.Method.RecordCopyValue, returnValue: Unmanaged.passRetained(contact.firstName! as AnyObject))
            mockAddressBook.mocker.prepareForCallTo(MockAddressBookWrapper.Method.RecordCopyValue, returnValue: Unmanaged.passRetained(contact.lastName! as AnyObject))

            ids.append(Int(contact.id))
        }
        
        // the contents of records don't matter here - just as long as the size is correct
        let records: [CFTypeRef] = ids
        let recordsPointer = UnsafeMutablePointer<UnsafePointer<Void>>(records)
        let recordsCFArray = CFArrayCreate(nil, recordsPointer, records.count, nil)
        mockAddressBook.mocker.prepareForCallTo(MockAddressBookWrapper.Method.AddressBookCopyArrayOfAllPeople, returnValue: Unmanaged.passRetained(recordsCFArray))
    }
}

class MockAddressBookWrapper: AddressBookWrapper {

    struct Method {
        static let AddressBookCreateWithOptions = "AddressBookCreateWithOptions"
        static let AddressBookGetAuthorizationStatus = "AddressBookGetAuthorizationStatus"
        static let AddressBookRequestAccessWithCompletion = "AddressBookRequestAccessWithCompletion"
        static let AddressBookCopyArrayOfAllPeople = "AddressBookCopyArrayOfAllPeople"
        static let RecordGetRecordID = "RecordGetRecordID"
        static let RecordCopyValue = "RecordCopyValue"
    }

    let mocker = Mocker()
    
    override func AddressBookCreateWithOptions(options: CFDictionary!, error: UnsafeMutablePointer<Unmanaged<CFError>?>) -> Unmanaged<ABAddressBook>! {
        mocker.recordCall(Method.AddressBookCreateWithOptions, parameters: options, error)
        return ABAddressBookCreateWithOptions(options, error)
    }
    
    override func AddressBookGetAuthorizationStatus() -> ABAuthorizationStatus {
        return mocker.mockCallTo(Method.AddressBookGetAuthorizationStatus) as ABAuthorizationStatus
    }
    
    override func AddressBookRequestAccessWithCompletion(addressBook: ABAddressBook!, completion: ABAddressBookRequestAccessCompletionHandler!) {
        mocker.recordCall(Method.AddressBookRequestAccessWithCompletion)
        //completion(true, nil)
    }
    
    override func AddressBookCopyArrayOfAllPeople(addressBook: ABAddressBook!) -> Unmanaged<CFArray>! {
        return mocker.mockCallTo(Method.AddressBookCopyArrayOfAllPeople) as Unmanaged<CFArray>!
    }
    
    override func RecordGetRecordID(record: ABRecord!) -> ABRecordID {
        var recordID: ABRecordID = 0
        let mockedRecordID = mocker.mockCallTo(Method.RecordGetRecordID, parameters: [record])
        if let mockedRecordID = mockedRecordID {
            recordID = mockedRecordID as ABRecordID
        }
        return recordID
    }
    
    override func RecordCopyValue(record: ABRecord!, property: ABPropertyID) -> Unmanaged<AnyObject>! {
        return mocker.mockCallTo(Method.RecordCopyValue, parameters: property) as Unmanaged<AnyObject>!
    }
}