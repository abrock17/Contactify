import Foundation

public class PlaylistService {
    
    public enum PlaylistResult {
        case Success(Playlist)
        case Failure(NSError)
    }
    
    let defaultSearchNumber = 20
    
    let contactService: ContactService
    let echoNestService: EchoNestService
    
    public init(contactService: ContactService = ContactService(), echoNestService: EchoNestService = EchoNestService()) {
        self.contactService = contactService
        self.echoNestService = echoNestService
    }
    
    public func createPlaylist(#numberOfSongs: Int, songPreferences: SongPreferences, callback: PlaylistResult -> Void) {
        contactService.retrieveAllContacts() {
            contactListResult in
            
            switch (contactListResult) {
            case .Success(let contactList):
                if contactList.isEmpty {
                    callback(.Failure(NSError(domain: Constants.Error.Domain, code: Constants.Error.NoContactsCode, userInfo: [NSLocalizedDescriptionKey: Constants.Error.NoContactsMessage])))
                } else {
                    self.createPlaylistForContactList(contactList, numberOfSongs: numberOfSongs, songPreferences: songPreferences, callback: callback)
                }
            case .Failure(let error):
                callback(.Failure(error))
            }
        }
    }
    
    func createPlaylistForContactList(contactList: [Contact], numberOfSongs: Int, songPreferences: SongPreferences, callback: PlaylistResult -> Void) {
        let defaultName = "Tune That Name"
        let searchableContacts = contactList.filter({$0.firstName != nil && !$0.firstName!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).isEmpty})
        let searchNumber = getEchoNestSearchNumberFor(totalRequestedNumberOfSongs: numberOfSongs, numberOfContacts: searchableContacts.count)
        var contactsToBeSearched = searchableContacts
        var contactsSearched = [Contact]()
        var contactSongsResultMap = [Contact: [Song]]()
        var searchCallbackCount = 0, searchErrorCount = 0
        var calledBack = false
        
        var findSongsForRandomName: (() -> ())!
        findSongsForRandomName = { () -> () in
            if !contactsToBeSearched.isEmpty {
                let randomIndex = Int(arc4random_uniform(UInt32(contactsToBeSearched.count)))
                let searchContact = contactsToBeSearched.removeAtIndex(randomIndex)
                contactsSearched.append(searchContact)
                self.echoNestService.findSongs(titleSearchTerm: searchContact.firstName!, songPreferences: songPreferences, desiredNumberOfSongs: searchNumber) {
                    songsResult in
                    
                    switch (songsResult) {
                    case .Success(let songs):
                        if !songs.isEmpty {
                            contactSongsResultMap[searchContact] = songs
                        } else {
                            findSongsForRandomName()
                        }
                        
                        if contactSongsResultMap.count == numberOfSongs {
                            calledBack = true
                            callback(.Success(self.buildPlaylistFromContactSongsResultMap(contactSongsResultMap, withName: defaultName, numberOfSongs: numberOfSongs)))
                        }
                    case .Failure(let error):
                        searchErrorCount++
                        println("Error finding songs for \(searchContact): \(error)")
                        
                        if  searchErrorCount >= 3 && searchErrorCount > (numberOfSongs / 5) {
                            if !calledBack {
                                calledBack = true
                                callback(.Failure(error))
                            }
                        } else {
                            findSongsForRandomName()
                        }
                    }
                    
                    searchCallbackCount++
                    if !calledBack && searchCallbackCount == searchableContacts.count {
                        calledBack = true
                        callback(.Success(self.buildPlaylistFromContactSongsResultMap(contactSongsResultMap, withName: defaultName, numberOfSongs: numberOfSongs)))
                    }
                }
            } else if !calledBack {
                calledBack = true
                if !contactSongsResultMap.isEmpty {
                callback(.Success(self.buildPlaylistFromContactSongsResultMap(contactSongsResultMap, withName: defaultName, numberOfSongs: numberOfSongs)))
                } else {
                    callback(.Failure(self.generalError()))
                }
            }
        }
        
        while contactsSearched.count < numberOfSongs && contactsToBeSearched.count > 0 {
            findSongsForRandomName()
        }
    }
    
    func getEchoNestSearchNumberFor(totalRequestedNumberOfSongs numberOfSongs: Int, numberOfContacts: Int) -> Int {
        let searchNumber: Int
        let minimumSearchNumber = Float(numberOfSongs) / Float(numberOfContacts)
        if minimumSearchNumber >= Float(defaultSearchNumber) / 2 {
            searchNumber = Int(round(minimumSearchNumber)) * 2
        } else {
            searchNumber = defaultSearchNumber
        }
        
        return searchNumber
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
    
    func generalError() -> NSError {
        return NSError(domain: Constants.Error.Domain,
            code: Constants.Error.PlaylistGeneralErrorCode,
            userInfo: [NSLocalizedDescriptionKey: Constants.Error.PlaylistGeneralErrorMessage])
    }
}