import Foundation

public class PlaylistService {
    
    public enum PlaylistResult {
        case Success(Playlist)
        case Failure(NSError)
    }
    
    let defaultSearchNumber = 20
    let unacceptableSongResultPercentage: Float = 0.0
    
    let contactService: ContactService
    let echoNestService: EchoNestService
    let spotifyUserService: SpotifyUserService
    
    public init(contactService: ContactService = ContactService(), echoNestService: EchoNestService = EchoNestService(),
        spotifyUserService: SpotifyUserService = SpotifyUserService()) {
        self.contactService = contactService
        self.echoNestService = echoNestService
        self.spotifyUserService = spotifyUserService
    }
    
    public func createPlaylistWithPreferences(playlistPreferences: PlaylistPreferences, callback: PlaylistResult -> Void) {
        func handleContactListResult(contactListResult: ContactService.ContactListResult) {
            switch (contactListResult) {
            case .Success(let contactList):
                if contactList.isEmpty {
                    callback(.Failure(NSError(domain: Constants.Error.Domain, code: Constants.Error.NoContactsCode, userInfo: [NSLocalizedDescriptionKey: Constants.Error.NoContactsMessage])))
                } else {
                    self.retrieveCurrentUser({
                        user in
                        self.createPlaylistForContactList(contactList, withPlaylistPreferences: playlistPreferences, inLocale: user.territory, callback: callback)
                    }, finalPlaylistResultCallback: callback)
                }
            case .Failure(let error):
                callback(.Failure(error))
            }
        }
        
        if playlistPreferences.filterContacts {
            contactService.retrieveFilteredContacts(handleContactListResult)
        } else {
            contactService.retrieveAllContacts(handleContactListResult)
        }
    }
    
    func retrieveCurrentUser(userRetrievalHandler: SPTUser -> Void, finalPlaylistResultCallback: PlaylistResult -> Void) {
        self.spotifyUserService.retrieveCurrentUser() {
            userResult in
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                switch (userResult) {
                case .Success(let user):
                    userRetrievalHandler(user)
                case .Failure(let error):
                    finalPlaylistResultCallback(.Failure(error))
                }
            }
        }
    }
    
    func createPlaylistForContactList(contactList: [Contact], withPlaylistPreferences playlistPreferences: PlaylistPreferences,
        inLocale locale: String?, callback: PlaylistResult -> Void) {
        let searchableContacts = contactList.filter({$0.firstName != nil && !$0.firstName!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).isEmpty})
        let searchNumber = getEchoNestSearchNumberFor(totalRequestedNumberOfSongs: playlistPreferences.numberOfSongs, numberOfContacts: searchableContacts.count)
        var contactSongsMap = [Contact: [Song]]()
        var contactErrorMap = [Contact: NSError]()
        let maxSongSearches = playlistPreferences.numberOfSongs + ((playlistPreferences.numberOfSongs - 5) / 9 + 5)
        let errorThreshold = min(searchableContacts.count, max(5, maxSongSearches / 3))
        
        var contactLists = separateNRandomForSearch(playlistPreferences.numberOfSongs, fromContacts: searchableContacts)
        repeat {
            let contactSongsResultMap = findSongsForContacts(contactLists.searchContacts, withPreferences: playlistPreferences.songPreferences, andSearchNumber: searchNumber, inLocale: locale)
            for (contact, songsResult) in contactSongsResultMap {
                switch (songsResult) {
                case .Success(let songs):
                    if !songs.isEmpty {
                        contactSongsMap[contact] = songs
                    } else {
                        print("No songs found for \(contact)")
                    }
                case .Failure(let error):
                    print("Error finding songs for \(contact): \(error)")
                    contactErrorMap[contact] = error
                }
            }
            
            let n = min((playlistPreferences.numberOfSongs - contactSongsMap.count),
                maxSongSearches - (contactSongsMap.count + contactErrorMap.count))
            contactLists = separateNRandomForSearch(n, fromContacts: contactLists.remainingContacts)
            print("searching for \(playlistPreferences.numberOfSongs) songs...\n\tcontactSongsMap=\(contactSongsMap.count)\n\tcontactErrorMap=\(contactErrorMap.count)\n\tn=\(n)")
        } while contactSongsMap.count < playlistPreferences.numberOfSongs
            && (contactSongsMap.count + contactErrorMap.count) < maxSongSearches
            && contactErrorMap.count < errorThreshold
            && !contactLists.searchContacts.isEmpty
        
        if contactErrorMap.count >= errorThreshold {
            callback(.Failure(generalError()))
        } else {
            let playlist = buildPlaylistFromContactSongsMap(contactSongsMap, numberOfSongs: playlistPreferences.numberOfSongs)
            if Float(playlist.songs.count) / Float(playlistPreferences.numberOfSongs) <= unacceptableSongResultPercentage {
                callback(.Failure(notEnoughSongsError()))
            } else {
                callback(.Success(playlist))
            }
        }
    }
    
    func separateNRandomForSearch(n: Int, fromContacts contacts: [Contact]) -> (searchContacts: [Contact], remainingContacts: [Contact]) {
        var randomContacts = [Contact]()
        var remainingContacts = contacts
        while randomContacts.count < n && !remainingContacts.isEmpty {
            let randomIndex = Int(arc4random_uniform(UInt32(remainingContacts.count)))
            let searchContact = remainingContacts.removeAtIndex(randomIndex)
            randomContacts.append(searchContact)
        }
        
        return (randomContacts, remainingContacts)
    }
    
    func findSongsForContacts(contacts: [Contact], withPreferences songPreferences: SongPreferences,
        andSearchNumber searchNumber: Int, inLocale locale: String?) -> [Contact: EchoNestService.SongsResult] {

        var contactSongsResultMap = Dictionary<Contact, EchoNestService.SongsResult>()
        let group = dispatch_group_create()
        for contact in contacts {
            dispatch_group_enter(group)
            self.echoNestService.findSongs(titleSearchTerm: contact.firstName!, withSongPreferences: songPreferences, desiredNumberOfSongs: searchNumber, inLocale: locale) {
                songsResult in
                
                contactSongsResultMap[contact] = songsResult
                dispatch_group_leave(group)
            }
        }
        
        dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, Int64(30.0 * Double(NSEC_PER_SEC))))
        return contactSongsResultMap
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
    
    func buildPlaylistFromContactSongsMap(contactSongsMap: [Contact: [Song]], numberOfSongs: Int) -> Playlist {
        print("building playlist with \(contactSongsMap.count) contacts")
        var songsWithContacts: [(song: Song, contact: Contact?)] = []
        var exhaustedContacts = [Contact]()
        
        while songsWithContacts.count < numberOfSongs && exhaustedContacts.count < contactSongsMap.count {
            for contact in contactSongsMap.keys {
                if !exhaustedContacts.contains(contact) {
                    var songAdded = false
                    for song in contactSongsMap[contact]! {
                        if !songsWithContacts.map({ $0.song }).contains(song) {
                            songsWithContacts.append(song: song, contact: contact as Contact?)
                            songAdded = true
                            break
                        }
                    }
                    if !songAdded {
                        exhaustedContacts.append(contact)
                    }
                }
                if songsWithContacts.count == numberOfSongs {
                    break
                }
            }
        }
    
        return Playlist(songsWithContacts: songsWithContacts)
    }
    
    func generalError() -> NSError {
        return NSError(domain: Constants.Error.Domain,
            code: Constants.Error.PlaylistGeneralErrorCode,
            userInfo: [NSLocalizedDescriptionKey: Constants.Error.PlaylistGeneralErrorMessage])
    }
    
    func notEnoughSongsError() -> NSError {
        return NSError(domain: Constants.Error.Domain,
            code: Constants.Error.PlaylistNotEnoughSongsCode,
            userInfo: [NSLocalizedDescriptionKey: Constants.Error.PlaylistNotEnoughSongsMessage])
    }
}