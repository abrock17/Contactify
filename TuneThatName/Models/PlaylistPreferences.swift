import Foundation

public class PlaylistPreferences: NSObject, NSCoding {
    
    public var numberOfSongs: Int
    public var filterContacts: Bool
    public var songPreferences: SongPreferences
    public override var description: String {
        return "PlaylistPreferences:[numberOfSongs:\(numberOfSongs), filterContacts:\(filterContacts), songPreferences:\(songPreferences)]"
    }
    
    public init(numberOfSongs: Int, filterContacts: Bool, songPreferences: SongPreferences) {
        self.numberOfSongs = numberOfSongs
        self.filterContacts = filterContacts
        self.songPreferences = songPreferences
    }
    
    public required convenience init(coder decoder: NSCoder) {
        let numberOfSongs = Int(decoder.decodeIntForKey("numberOfSongs"))
        let filterContacts = decoder.decodeBoolForKey("filterContacts")
        let songPreferences = decoder.decodeObjectForKey("songPreferences") as! SongPreferences
        self.init(numberOfSongs: numberOfSongs, filterContacts: filterContacts, songPreferences: songPreferences)
    }
    
    public func encodeWithCoder(coder: NSCoder) {
        coder.encodeInt(Int32(self.numberOfSongs), forKey: "numberOfSongs")
        coder.encodeBool(self.filterContacts, forKey: "filterContacts")
        coder.encodeObject(self.songPreferences, forKey: "songPreferences")
    }
    
    override public func isEqual(object: AnyObject?) -> Bool {
        let equal: Bool
        if let playlistPreferences = object as? PlaylistPreferences {
            equal = self == playlistPreferences
        } else {
            equal = false
        }
        
        return equal
    }
}

public func ==(x: PlaylistPreferences, y: PlaylistPreferences) -> Bool {
    return x.numberOfSongs == y.numberOfSongs
        && x.filterContacts == y.filterContacts
        && x.songPreferences == y.songPreferences
}