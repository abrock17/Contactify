import TuneThatName

class MockContactService: ContactService {
    
    struct Method {
        static let retrieveAllContacts = "retrieveAllContacts"
        static let retrieveFilteredContacts = "retrieveFilteredContacts"
        static let saveFilteredContacts = "saveFilteredContacts"
    }
    
    let mocker = Mocker()
    
    override func retrieveAllContacts(callback: ContactListResult -> Void) {
        mocker.recordCall(Method.retrieveAllContacts)
        let contactListResult: ContactListResult
        if let mockedContactListResult = mocker.returnValueForCallTo(Method.retrieveAllContacts) as? ContactListResult {
            contactListResult = mockedContactListResult
        } else {
            contactListResult = ContactService.ContactListResult.Success([])
        }
        callback(contactListResult)
    }
    
    override func retrieveFilteredContacts(callback: ContactService.ContactListResult -> Void) {
        mocker.recordCall(Method.retrieveFilteredContacts)
        let contactListResult: ContactListResult
        if let mockedContactListResult = mocker.returnValueForCallTo(Method.retrieveFilteredContacts) as? ContactListResult {
            contactListResult = mockedContactListResult
        } else {
            contactListResult = ContactService.ContactListResult.Success([])
        }
        callback(contactListResult)
    }
    
    override func saveFilteredContacts(contacts: [Contact]) {
        mocker.recordCall(Method.saveFilteredContacts, parameters: contacts)
    }
}