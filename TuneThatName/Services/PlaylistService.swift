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
        var contactsSearched = [Contact]()
        var contactsNotYetSearched = contactList
        
        while contactsSearched.count < numberOfSongs {
            let randomIndex = Int(arc4random_uniform(UInt32(contactsNotYetSearched.count)))
            let searchContact = contactsNotYetSearched.removeAtIndex(randomIndex)
            contactsSearched.append(searchContact)
            self.echoNestService.findSong(titleSearchTerm: searchContact.firstName!) {
                songResult in
                
                // add to playlist
            }
        }
    }
}