import Foundation
import AddressBook

public class ContactService {
    
    public enum ContactListResult {
        case Success([Contact])
        case Failure(NSError)
    }
    
    let addressBook: AddressBookWrapper
    let userDefaults: NSUserDefaults
    
    public init(addressBook: AddressBookWrapper = AddressBookWrapper(),
        userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()) {
        self.addressBook = addressBook
        self.userDefaults = userDefaults
    }
    
    public func retrieveAllContacts(callback: ContactListResult -> Void) {
        handleAuthorizationForCallback(callback, authorizedHandler: getContactList)
    }
    
    func handleAuthorizationForCallback(callback: ContactListResult -> Void,
        authorizedHandler: (ContactListResult -> Void) -> Void) {
            
        let authorizationStatus = addressBook.AddressBookGetAuthorizationStatus()
        switch (authorizationStatus) {
        case .Denied, .Restricted:
            callback(.Failure(self.noAccessError()))
        case .Authorized:
            authorizedHandler(callback)
        case .NotDetermined:
            let addressBookRef: ABAddressBookRef = addressBook.AddressBookCreateWithOptions(nil, error: nil).takeRetainedValue()
            addressBook.AddressBookRequestAccessWithCompletion(addressBookRef) {
                (granted, cfError) in
                
                if cfError != nil {
                    let error = NSError(domain: CFErrorGetDomain(cfError) as String, code: CFErrorGetCode(cfError) as Int, userInfo: CFErrorCopyUserInfo(cfError) as Dictionary)
                    callback(.Failure(error))
                } else if granted {
                    authorizedHandler(callback)
                } else {
                    callback(.Failure(self.noAccessError()))
                }
            }
        }
    }
    
    func getContactList(callback: ContactListResult -> Void) {
        var contactList = [Contact]()
        let addressBookRef: ABAddressBookRef = addressBook.AddressBookCreateWithOptions(nil, error: nil).takeRetainedValue()
        let records = addressBook.AddressBookCopyArrayOfAllPeople(addressBookRef).takeRetainedValue() as Array
        for recordRef: ABRecordRef in records {
            let recordID = addressBook.RecordGetRecordID(recordRef)
            let firstName = addressBook.RecordCopyValue(recordRef, property: kABPersonFirstNameProperty)?.takeRetainedValue() as? String
            let lastName = addressBook.RecordCopyValue(recordRef, property: kABPersonLastNameProperty)?.takeRetainedValue() as? String
            let fullName = addressBook.RecordCopyCompositeName(recordRef)?.takeRetainedValue() as? String
            contactList.append(Contact(id: recordID, firstName: firstName, lastName: lastName, fullName: fullName))
        }
        
        callback(.Success(contactList))
    }
    
    func noAccessError() -> NSError {
        return NSError(
            domain: Constants.Error.Domain,
            code: Constants.Error.AddressBookNoAccessCode,
            userInfo: [NSLocalizedDescriptionKey: Constants.Error.AddressBookNoAccessMessage])
    }
    
    public func retrieveFilteredContacts(callback: ContactListResult -> Void) {
        var filteredContacts = [Contact]()
        if let contactDataArray = userDefaults.arrayForKey(Constants.StorageKeys.filteredContacts) as? [NSData] {
            retrieveAllContacts() {
                contactListResult in
                
                switch contactListResult {
                case .Success(let contacts):
                    let archivedFilteredContacts = contactDataArray.map({ NSKeyedUnarchiver.unarchiveObjectWithData($0) as! Contact })
                    for filteredContact in archivedFilteredContacts {
                        var matchingContacts = contacts.filter({ $0.id == filteredContact.id })
                        if matchingContacts.isEmpty {
                            matchingContacts = contacts.filter({
                                $0.firstName == filteredContact.firstName && $0.lastName == filteredContact.lastName })
                        }
                        if !matchingContacts.isEmpty {
                            filteredContacts.append(matchingContacts.first!)
                        }
                    }
                    callback(.Success(filteredContacts))
                case .Failure(let error):
                    print("Error retrieving all contacts for filtering : \(filteredContacts)")
                    callback(.Failure(error))
                }
            }
        } else {
            callback(.Success(filteredContacts))
        }
    }
    
    public func saveFilteredContacts(contacts: [Contact]) {
        let contactDataArray = contacts.map({ NSKeyedArchiver.archivedDataWithRootObject($0) })
        userDefaults.setObject(contactDataArray, forKey: Constants.StorageKeys.filteredContacts)
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
    
    public func RecordCopyCompositeName(record: ABRecord!) -> Unmanaged<CFString>! {
        return ABRecordCopyCompositeName(record)
    }
}
