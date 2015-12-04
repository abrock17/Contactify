import Foundation

public class PreferencesService {
    
    let userDefaults: NSUserDefaults
    
    public init(userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()) {
            self.userDefaults = userDefaults
    }
    
    public func getDefaultPlaylistPreferences() -> PlaylistPreferences {
        return PlaylistPreferences(numberOfSongs: 10, filterContacts: false, songPreferences: SongPreferences(characteristics: Set<SongPreferences.Characteristic>([.Popular])))
    }
    
    public func retrievePlaylistPreferences() -> PlaylistPreferences? {
        var playlistPreferences: PlaylistPreferences? = nil
        if let preferencesData = userDefaults.dataForKey(Constants.StorageKeys.playlistPreferences) {
            playlistPreferences = NSKeyedUnarchiver.unarchiveObjectWithData(preferencesData) as? PlaylistPreferences
        }
        
        if let playlistPreferences = playlistPreferences {
            if playlistPreferences.filterContacts {
                let contactDataArray = userDefaults.arrayForKey(Constants.StorageKeys.filteredContacts)
                if let array = contactDataArray {
                    if array.isEmpty {
                         playlistPreferences.filterContacts = false
                    }
                } else {
                    playlistPreferences.filterContacts = false
                }
            }
        }
        
        return playlistPreferences
    }
    
    public func savePlaylistPreferences(playlistPreferences: PlaylistPreferences) {
        userDefaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(playlistPreferences), forKey: Constants.StorageKeys.playlistPreferences)
    }
}