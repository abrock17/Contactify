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
        var contactsToBeSearched = [Contact]()
        var songResultList = [Song]()
        var errorResultList = [NSError]()
        var calledBack = false
        
        var findSongForRandomName: (() -> ())!
        findSongForRandomName = { () -> () in
            if contactsToBeSearched.isEmpty {
                contactsToBeSearched = searchableContacts
            }
            
            let randomIndex = Int(arc4random_uniform(UInt32(contactsToBeSearched.count)))
            let searchContact = contactsToBeSearched.removeAtIndex(randomIndex)
            contactsSearched.append(searchContact)
            self.echoNestService.findSongs(titleSearchTerm: searchContact.firstName!, number: 1) {
                songsResult in
                
                switch (songsResult) {
                case .Success(let songs):
                    if !songs.isEmpty {
                        songResultList.append(songs[0])
                    } else {
                        findSongForRandomName()
                    }
                    
                    if numberOfSongs == songResultList.count {
                        calledBack = true
                        callback(.Success(Playlist(name: "Tune That Name", uri: nil, songs: songResultList)))
                    }
                case .Failure(let error):
                    errorResultList.append(error)
                    println("Error \(errorResultList.count) finding song: \(error)")
                    
                    if  errorResultList.count >= 3 && errorResultList.count > (numberOfSongs / 5) {
                        if !calledBack {
                            calledBack = true
                            callback(.Failure(error))
                        }
                    } else {
                        findSongForRandomName()
                    }
                }
            }
        }
        
        while contactsSearched.count < numberOfSongs {
            findSongForRandomName()
        }
    }
}