import Foundation

public struct Song: Equatable {
    public let title: String!
    public let artistName: String?
    public let uri: NSURL?
    
    public init(title: String!, artistName: String?, uri: NSURL!) {
        self.title = title
        self.artistName = artistName
        self.uri = uri
    }
}

public func ==(x: Song, y: Song) -> Bool {
    return x.title == y.title && x.uri == y.uri
}
