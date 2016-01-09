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
            var mockUserDefaults: MockUserDefaults!
            
            beforeEach() {
                self.callbackContactList = nil
                self.callbackError = nil
                mockAddressBook = MockAddressBookWrapper()
                mockUserDefaults = MockUserDefaults()
                contactService = ContactService(addressBook: mockAddressBook, userDefaults: mockUserDefaults)
            }
            
            describe("retrieve all contacts") {
                context("when access to the address book is denied") {
                    it("calls back with the no access error") {
                        mockAddressBook.mocker.prepareForCallTo(MockAddressBookWrapper.Method.AddressBookGetAuthorizationStatus, returnValue: ABAuthorizationStatus.Denied)
                        
                        contactService.retrieveAllContacts(self.contactListCallback)
                        
                        expect(self.callbackError).toEventually(equal(self.expectedNoAccessError))
                        expect(self.callbackContactList).to(beNil())
                    }
                }
                
                context("when access to the address book is restricted") {
                    it("calls back with the no access error") {
                        mockAddressBook.mocker.prepareForCallTo(MockAddressBookWrapper.Method.AddressBookGetAuthorizationStatus, returnValue: ABAuthorizationStatus.Restricted)
                        
                        contactService.retrieveAllContacts(self.contactListCallback)
                        
                        expect(self.callbackError).toEventually(equal(self.expectedNoAccessError))
                        expect(self.callbackContactList).to(beNil())
                    }
                }
                
                context("when authorized to access the address book") {
                    beforeEach() {
                        mockAddressBook.mocker.prepareForCallTo(MockAddressBookWrapper.Method.AddressBookGetAuthorizationStatus, returnValue: ABAuthorizationStatus.Authorized)
                    }
                    
                    it("calls back with a list of expected contacts") {
                        let expectedContactList = [
                            Contact(id: 1, firstName: "billy", lastName: "johnson", fullName: "billy johnson"),
                            Contact(id: 2, firstName: "johnny", lastName: "billson", fullName: "johnny billson")
                        ]
                        self.prepareMockAddressBook(mockAddressBook, withContactList: expectedContactList)
                        
                        contactService.retrieveAllContacts(self.contactListCallback)

                        expect(self.callbackContactList).toEventually(equal(expectedContactList))
                        expect(self.callbackError).to(beNil())
                    }
                    
                    context("when a contact has all blank or empty name fields") {
                        it("excludes it from the list") {
                            let expectedContactList = [
                                Contact(id: 1, firstName: "billy", lastName: "johnson", fullName: "billy johnson")
                            ]
                            self.prepareMockAddressBook(mockAddressBook,
                                withContactList: [
                                    expectedContactList.first!,
                                    Contact(id: 2, firstName: "", lastName: "", fullName: " ")
                                ]
                            )
                            
                            contactService.retrieveAllContacts(self.contactListCallback)
                            
                            expect(self.callbackContactList).toEventually(equal(expectedContactList))
                            expect(self.callbackError).to(beNil())
                        }
                    }
                    
                    context("and address book has duplicate names") {
                        it("excludes the duplicates") {
                            let contact = Contact(id: 1, firstName: "Ned", lastName: "Nederlander")
                            let contactWithSingleName = Contact(id: 2, firstName: "Madonna", lastName: "")
                            let expectedContactList = [contact, contactWithSingleName]
                            self.prepareMockAddressBook(mockAddressBook,
                                withContactList: [
                                    contact,
                                    contactWithSingleName,
                                    Contact(id: 3, firstName: contact.firstName, lastName: contact.lastName),
                                    Contact(id: 4, firstName: "", lastName: contactWithSingleName.lastName),
                                ]
                            )
                            
                            contactService.retrieveAllContacts(self.contactListCallback)
                            
                            expect(self.callbackContactList).toEventually(equal(expectedContactList))
                            expect(self.callbackError).to(beNil())
                        }
                    }
                }
                
                context("when the application's access to the address book has not been determined") {
                    beforeEach() {
                        mockAddressBook.mocker.prepareForCallTo(MockAddressBookWrapper.Method.AddressBookGetAuthorizationStatus, returnValue: ABAuthorizationStatus.NotDetermined)
                    }
                    
                    it("prompts the user for access") {
                        let expectedContactList = [Contact(id: 3, firstName: "mikhail", lastName: "gorbachev", fullName:  "gorby"), Contact(id: 4, firstName: "ronald", lastName: "reagan", fullName: "ronnie")]
                        self.prepareMockAddressBook(mockAddressBook, withContactList: expectedContactList)
                        mockAddressBook.mocker.prepareForCallTo(MockAddressBookWrapper.Method.AddressBookRequestAccessWithCompletion, returnValue: true)

                        contactService.retrieveAllContacts(self.contactListCallback)

                        self.verifyPromptedForAccess(mockAddressBook)

                        context("and access is granted") {
                            it("calls back with a list of expected contacts") {
                                expect(self.callbackContactList).toEventually(equal(expectedContactList))
                                expect(self.callbackError).to(beNil())
                            }
                        }
                    }
                    
                    context("and access is not granted") {
                        it("calls back with the no access error") {
                            mockAddressBook.mocker.prepareForCallTo(MockAddressBookWrapper.Method.AddressBookRequestAccessWithCompletion, returnValue: false)

                            contactService.retrieveAllContacts(self.contactListCallback)
                            
                            expect(self.callbackError).toEventually(equal(self.expectedNoAccessError))
                            expect(self.callbackContactList).to(beNil())
                        }
                    }
                    
                    context("and access request completion return an error") {
                        it("calls back with the same error") {
                            let expectedError = NSError(domain: "domain", code: 777, userInfo: ["key": "value"])
                            let mockedError = CFErrorCreate(nil, expectedError.domain, expectedError.code, expectedError.userInfo)
                            mockAddressBook.mocker.prepareForCallTo(MockAddressBookWrapper.Method.AddressBookRequestAccessWithCompletion, returnValue: mockedError)
                            
                            contactService.retrieveAllContacts(self.contactListCallback)
                            
                            expect(self.callbackError).toEventually(equal(expectedError))
                            expect(self.callbackContactList).to(beNil())
                        }
                    }
                }
            }
            
            describe("retrieve filtered contacts") {
                context("when there are no filtered contacts") {
                    it("calls back with an empty list") {
                        mockUserDefaults.mocker.prepareForCallTo(MockUserDefaults.Method.arrayForKey, returnValue: nil)
                        
                        contactService.retrieveFilteredContacts(self.contactListCallback)
                        
                        expect(self.callbackContactList).toEventually(equal([]))
                        expect(self.callbackError).to(beNil())
                    }
                }
            
                context("when there are filtered contacts") {
                    let addressBookContactList = [Contact(id: 1, firstName: "billy", lastName: "johnson", fullName: "billy johnson"), Contact(id: 2, firstName: "johnny", lastName: "billson", fullName: "johnny billson")]
                    let filteredContact = Contact(id: 98765, firstName: addressBookContactList.last?.firstName, lastName: addressBookContactList.last?.lastName)
                    let filteredContactDataList = [NSKeyedArchiver.archivedDataWithRootObject(filteredContact)]

                    beforeEach() {
                        mockUserDefaults.mocker.prepareForCallTo(MockUserDefaults.Method.arrayForKey, returnValue: filteredContactDataList)
                    }
                    
                    context("and access to the address book is denied") {
                        it("calls back with the no access error") {
                            mockAddressBook.mocker.prepareForCallTo(MockAddressBookWrapper.Method.AddressBookGetAuthorizationStatus, returnValue: ABAuthorizationStatus.Denied)
                            
                            contactService.retrieveFilteredContacts(self.contactListCallback)
                            
                            expect(self.callbackError).toEventually(equal(self.expectedNoAccessError))
                            expect(self.callbackContactList).to(beNil())
                        }
                    }
                    
                    context("and address book contact retrieval is successful") {
                        beforeEach() {
                            mockAddressBook.mocker.prepareForCallTo(MockAddressBookWrapper.Method.AddressBookGetAuthorizationStatus, returnValue: ABAuthorizationStatus.Authorized)
                            
                            self.prepareMockAddressBook(mockAddressBook, withContactList: addressBookContactList)
                        }
                        
                        it("calls back with the same contact from the address book") {
                            contactService.retrieveFilteredContacts(self.contactListCallback)
                            
                            expect(self.callbackContactList?.count).toEventually(equal(1))
                            expect(self.callbackContactList?.first?.id)
                                .to(equal(addressBookContactList.last?.id))
                            expect(self.callbackContactList?.first?.firstName)
                                .to(equal(addressBookContactList.last?.firstName))
                            expect(self.callbackContactList?.first?.lastName)
                                .to(equal(addressBookContactList.last?.lastName))
                            expect(self.callbackContactList?.first?.fullName)
                                .to(equal(addressBookContactList.last?.fullName))
                            expect(self.callbackError).to(beNil())
                        }
                    }
                }
            }
        }
    }
    
    func prepareMockAddressBook(mockAddressBook: MockAddressBookWrapper, withContactList contactList: [Contact]) {
        var ids = [AnyObject]()
        
        for contact in contactList {
            mockAddressBook.mocker.prepareForCallTo(MockAddressBookWrapper.Method.RecordGetRecordID, returnValue: contact.id)
            mockAddressBook.mocker.prepareForCallTo(MockAddressBookWrapper.Method.RecordCopyValue, returnValue: Unmanaged.passRetained(contact.firstName as! AnyObject))
            mockAddressBook.mocker.prepareForCallTo(MockAddressBookWrapper.Method.RecordCopyValue, returnValue: Unmanaged.passRetained(contact.lastName as! AnyObject))
            mockAddressBook.mocker.prepareForCallTo(MockAddressBookWrapper.Method.RecordCopyCompositeName, returnValue: Unmanaged.passRetained(contact.fullName as CFStringRef))

            ids.append(Int(contact.id))
        }
        
        // the contents of records don't matter here - just as long as the size is correct
        let records: [CFTypeRef] = ids
        let recordsPointer = UnsafeMutablePointer<UnsafePointer<Void>>(records)
        let recordsCFArray = CFArrayCreate(nil, recordsPointer, records.count, nil)
        mockAddressBook.mocker.prepareForCallTo(MockAddressBookWrapper.Method.AddressBookCopyArrayOfAllPeople, returnValue: Unmanaged.passRetained(recordsCFArray))
    }
    
    func verifyPromptedForAccess(mockAddressBook: MockAddressBookWrapper) {
        expect(mockAddressBook.mocker.getNthCallTo(MockAddressBookWrapper.Method.AddressBookRequestAccessWithCompletion, n: 0)).toNot(beNil())
        expect(mockAddressBook.mocker.getNthCallTo(MockAddressBookWrapper.Method.AddressBookRequestAccessWithCompletion, n: 0)).to(beEmpty())
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
        static let RecordCopyCompositeName = "RecordCopyCompositeName"
    }

    let mocker = Mocker()
    
    override func AddressBookCreateWithOptions(options: CFDictionary!, error: UnsafeMutablePointer<Unmanaged<CFError>?>) -> Unmanaged<ABAddressBook>! {
        mocker.recordCall(Method.AddressBookCreateWithOptions, parameters: options, error)
        return ABAddressBookCreateWithOptions(options, error)
    }
    
    override func AddressBookGetAuthorizationStatus() -> ABAuthorizationStatus {
        return mocker.mockCallTo(Method.AddressBookGetAuthorizationStatus) as! ABAuthorizationStatus
    }
    
    override func AddressBookRequestAccessWithCompletion(addressBook: ABAddressBook!, completion: ABAddressBookRequestAccessCompletionHandler!) {
        mocker.recordCall(Method.AddressBookRequestAccessWithCompletion)
        let preparedResult = mocker.returnValueForCallTo(Method.AddressBookRequestAccessWithCompletion)
        if let granted = preparedResult as? Bool {
            completion(granted, nil)
        } else if let error = preparedResult as! CFError! {
            completion(false, error)
        } else {
            completion(false, nil)
        }
    }
    
    override func AddressBookCopyArrayOfAllPeople(addressBook: ABAddressBook!) -> Unmanaged<CFArray>! {
        return mocker.mockCallTo(Method.AddressBookCopyArrayOfAllPeople) as! Unmanaged<CFArray>!
    }
    
    override func RecordGetRecordID(record: ABRecord!) -> ABRecordID {
        var recordID: ABRecordID = 0
        let mockedReturnValue = mocker.mockCallTo(Method.RecordGetRecordID, parameters: [record])
        if let mockedRecordID = mockedReturnValue as? ABRecordID {
            recordID = mockedRecordID
        }
        return recordID
    }
    
    override func RecordCopyValue(record: ABRecord!, property: ABPropertyID) -> Unmanaged<AnyObject>! {
        return mocker.mockCallTo(Method.RecordCopyValue, parameters: property) as! Unmanaged<AnyObject>!
    }
    
    override func RecordCopyCompositeName(record: ABRecord!) -> Unmanaged<CFString> {
        return mocker.mockCallTo(Method.RecordCopyCompositeName) as! Unmanaged<CFString>!
    }
}
