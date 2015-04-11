import Foundation
import AddressBook

public class ContactService {
    
    public enum ContactListResult {
        case Success([Contact])
        case Failure(NSError)
    }
    
    let addressBook: AddressBookWrapper!
    
    public init(addressBook: AddressBookWrapper = AddressBookWrapper()) {
        self.addressBook = addressBook
    }
    
    public func retrieveAllContacts(callback: (ContactListResult) -> Void) {
        let authorizationStatus = addressBook.AddressBookGetAuthorizationStatus()
        switch (authorizationStatus) {
        case .Denied, .Restricted:
            callback(.Failure(NSError(domain: Constants.Error.Domain, code: Constants.Error.AddressBookNoAccessCode, userInfo: [NSLocalizedDescriptionKey: Constants.Error.AddressBookNoAccessMessage])))
        case .Authorized:
            var contactList = getContactList()
            callback(.Success(contactList))
        default:
            println("status : \(authorizationStatus.rawValue)")
        }
    }
    
    func getContactList() -> [Contact] {
        var contactList = [Contact]()
        let addressBookRef: ABAddressBookRef = addressBook.AddressBookCreateWithOptions(nil, error: nil).takeRetainedValue()
        let records: Array = addressBook.AddressBookCopyArrayOfAllPeople(addressBookRef).takeRetainedValue()
        for recordRef: ABRecordRef in records {
            let recordID = addressBook.RecordGetRecordID(recordRef)
            let firstName = addressBook.RecordCopyValue(recordRef, property: kABPersonFirstNameProperty).takeRetainedValue() as? String
            let lastName = addressBook.RecordCopyValue(recordRef, property: kABPersonLastNameProperty).takeRetainedValue() as? String
            contactList.append(Contact(id: recordID, firstName: firstName, lastName: lastName))
        }
        
        return contactList
    }
}

public class AddressBookWrapper {
    
    public init() {
    }
    
    public func AddressBookCreateWithOptions(options: CFDictionary!, error: UnsafeMutablePointer<Unmanaged<CFError>?>) -> Unmanaged<ABAddressBook>! {
        return ABAddressBookCreateWithOptions(options, error)
    }
    
    public func AddressBookGetAuthorizationStatus() -> ABAuthorizationStatus {
        return ABAddressBookGetAuthorizationStatus()
    }
    
    public func AddressBookRequestAccessWithCompletion(addressBook: ABAddressBook!, completion: ABAddressBookRequestAccessCompletionHandler!) {
        ABAddressBookRequestAccessWithCompletion(addressBook, completion)
    }
    
    public func AddressBookCopyArrayOfAllPeople(addressBook: ABAddressBook!) -> Unmanaged<CFArray>! {
        return ABAddressBookCopyArrayOfAllPeople(addressBook)
    }
    
    public func RecordGetRecordID(record: ABRecord!) -> ABRecordID {
        return ABRecordGetRecordID(record)
    }
    
    public func RecordCopyValue(record: ABRecord!, property: ABPropertyID) -> Unmanaged<AnyObject>! {
        return ABRecordCopyValue(record, property)
    }
}
