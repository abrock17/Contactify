import Foundation

public class PlaylistService {
    
    public enum PlaylistResult {
        case Success(Playlist)
        case Failure(NSError)
    }
    
    let contactService: ContactService
    let echoNestService: EchoNestService
    
    public init(contactService: ContactService = ContactService(), echoNestService: EchoNestService = EchoNestService()) {
        self.contactService = contactService
        self.echoNestService = echoNestService
    }
    
    public func createPlaylist(#numberOfSongs: Int, callback: PlaylistResult -> Void) {
        contactService.retrieveAllContacts() {
            contactListResult in
            
            switch (contactListResult) {
            case .Success(var contactList):
                if contactList.isEmpty {
                    callback(.Failure(NSError(domain: Constants.Error.Domain, code: Constants.Error.NoContactsCode, userInfo: [NSLocalizedDescriptionKey: Constants.Error.NoContactsMessage])))
                } else {
                    self.createPlaylistForContactList(contactList, numberOfSongs: numberOfSongs, callback: callback)
                }
            case .Failure(let error):
                callback(.Failure(error))
            }
        }
    }
    
    func createPlaylistForContactList(contactList: [Contact], numberOfSongs: Int, callback: PlaylistResult -> Void) {
        let searchableContacts = contactList.filter({$0.firstName != nil && !$0.firstName!.isEmpty})
        var contactsSearched = [Contact]()
        var contactsToBeSearched = searchableContacts
        
        while contactsSearched.count < numberOfSongs {
            if contactsToBeSearched.isEmpty {
                contactsToBeSearched = searchableContacts
            }
            
            let randomIndex = Int(arc4random_uniform(UInt32(contactsToBeSearched.count)))
            let searchContact = contactsToBeSearched.removeAtIndex(randomIndex)
            contactsSearched.append(searchContact)
            self.echoNestService.findSong(titleSearchTerm: searchContact.firstName!) {
                songResult in
                
                // add to playlist
            }
        }
    }
}