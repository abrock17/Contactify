import Foundation

public class PlaylistService {
    
    let defaultSearchNumber = 20
    
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
        var contactsToBeSearched = searchableContacts
        var contactsSearched = [Contact]()
        var contactSongsResultMap = [Contact: [Song]]()
        var contactErrorResultMap = [Contact: NSError]()
        var calledBack = false
        
        var findSongsForRandomName: (() -> ())!
        findSongsForRandomName = { () -> () in
            
            let randomIndex = Int(arc4random_uniform(UInt32(contactsToBeSearched.count)))
            let searchContact = contactsToBeSearched.removeAtIndex(randomIndex)
            contactsSearched.append(searchContact)
            self.echoNestService.findSongs(titleSearchTerm: searchContact.firstName!, number: self.defaultSearchNumber) {
                songsResult in
                
                switch (songsResult) {
                case .Success(let songs):
                    if !songs.isEmpty {
                        contactSongsResultMap[searchContact] = songs
                    } else {
                        findSongsForRandomName()
                    }
                    
                    if contactSongsResultMap.count == numberOfSongs
                        || contactSongsResultMap.count == searchableContacts.count {
                        calledBack = true
                            callback(.Success(self.buildPlaylistFromContactSongsResultMap(contactSongsResultMap, withName: "Tune That Name", numberOfSongs: numberOfSongs)))
                    }
                case .Failure(let error):
                    contactErrorResultMap[searchContact] = error
                    println("Error finding songs for \(searchContact): \(error)")
                    
                    if  contactErrorResultMap.count >= 3 && contactErrorResultMap.count > (numberOfSongs / 5) {
                        if !calledBack {
                            calledBack = true
                            callback(.Failure(error))
                        }
                    } else {
                        findSongsForRandomName()
                    }
                }
            }
        }
        
        while contactsSearched.count < numberOfSongs && contactsSearched.count < searchableContacts.count {
            findSongsForRandomName()
        }
    }
    
    func buildPlaylistFromContactSongsResultMap(contactSongsResultMap: [Contact: [Song]], withName name: String, numberOfSongs: Int) -> Playlist {
        var playlistSongs = [Song]()
        var exhaustedContacts = [Contact]()
        while playlistSongs.count < numberOfSongs && exhaustedContacts.count < contactSongsResultMap.count {
            for contact in contactSongsResultMap.keys {
                if !contains(exhaustedContacts, contact) {
                    var songAdded = false
                    for contactSong in contactSongsResultMap[contact]! {
                        if !contains(playlistSongs, contactSong) {
                            playlistSongs.append(contactSong)
                            songAdded = true
                            break
                        }
                    }
                    if !songAdded {
                        exhaustedContacts.append(contact)
                    }
                }
                if playlistSongs.count == numberOfSongs {
                    break
                }
            }
        }
    
        return Playlist(name: name, uri: nil, songs: playlistSongs)
    }
}