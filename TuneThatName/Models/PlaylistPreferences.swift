import Foundation

public struct PlaylistPreferences: Equatable, Printable {
    
    public var numberOfSongs: Int
    public var filterContacts: Bool
    public var songPreferences: SongPreferences
    public var description: String {
        return "PlaylistPreferences:[numberOfSongs:\(numberOfSongs), filterContacts:\(filterContacts), songPreferences:\(songPreferences)]"
    }
    
    public init(numberOfSongs: Int, filterContacts: Bool, songPreferences: SongPreferences) {
        self.numberOfSongs = numberOfSongs
        self.filterContacts = filterContacts
        self.songPreferences = songPreferences
    }
}

public func ==(x: PlaylistPreferences, y: PlaylistPreferences) -> Bool {
    return x.numberOfSongs == y.numberOfSongs
        && x.filterContacts == y.filterContacts
        && x.songPreferences == y.songPreferences
}