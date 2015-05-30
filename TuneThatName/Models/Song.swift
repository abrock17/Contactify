import Foundation

public struct Song: Equatable, Hashable, Printable {

    public let title: String!
    public let artistName: String?
    public let uri: NSURL
    public var description: String {
        return "Song:[title:\(title), artistName:\(artistName), uri:\(uri)]"
    }
    
    public var hashValue: Int {
        return "\(description)".hashValue
    }
    
    public init(title: String!, artistName: String?, uri: NSURL) {
        self.title = title
        self.artistName = artistName
        self.uri = uri
    }
}

public func ==(x: Song, y: Song) -> Bool {
    return x.title == y.title && x.uri == y.uri
}
