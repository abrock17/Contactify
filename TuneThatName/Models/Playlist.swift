import Foundation

public struct Playlist: Equatable, Printable {
    
    public var name: String?
    public var uri: NSURL?
    public var songsWithContacts: [(song: Song, contact: Contact?)]
    public var songs: [Song] {
        return self.songsWithContacts.map({ $0.song })
    }
    public var songURIs: [NSURL] {
        return self.songsWithContacts.map({ $0.song.uri })
    }
    public var description: String {
        return "Playlist:[name:\(name), uri:\(uri), number of songs:\(songs.count)]"
    }
    
    public init(name: String! = nil, uri: NSURL! = nil, songsWithContacts: [(song: Song, contact: Contact?)] = []) {
        self.name = name
        self.uri = uri
        self.songsWithContacts = songsWithContacts
    }
}

public func ==(x: Playlist, y: Playlist) -> Bool {
    return x.name == y.name && x.uri == y.uri && x.songs == y.songs
}
