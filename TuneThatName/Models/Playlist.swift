import Foundation

public struct Playlist: Equatable {
    
    public let name: String!
    public var uri: NSURL?
    public var songs = [Song]()
    
    public init(name: String!) {
        self.name = name
    }

    public init(name: String!, uri: NSURL!) {
        self.name = name
        self.uri = uri
    }

    public init(name: String!, uri: NSURL!, songs: [Song]!) {
        self.name = name
        self.uri = uri
        self.songs = songs
    }
}

public func ==(x: Playlist, y: Playlist) -> Bool {
    return x.name == y.name && x.uri == y.uri && x.songs == y.songs
}
