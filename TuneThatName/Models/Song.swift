import Foundation

public struct Song: Equatable, Hashable, Printable {
    
    static func formattedDisplayNameForArtistNames(artistNames: [String]) -> String! {
        let displayArtistName: String!
        if artistNames.isEmpty {
            displayArtistName = nil
        } else if artistNames.count == 1 {
            displayArtistName = artistNames.first
        } else {
            let allButLast = artistNames[0..<artistNames.endIndex - 1]
            displayArtistName = ", ".join(allButLast) + " and " + artistNames.last!
        }
        
        return displayArtistName
    }

    public let title: String!
    public let uri: NSURL
    public let artistNames: [String]
    public var displayArtistName: String! {
        return Song.formattedDisplayNameForArtistNames(self.artistNames)
    }
    public var description: String {
        return "Song:[title:\(title), artistNames:\(artistNames), uri:\(uri)]"
    }
    
    public var hashValue: Int {
        return "\(description)".hashValue
    }
    
    public init(title: String, artistNames: [String], uri: NSURL) {
        self.title = title
        self.artistNames = artistNames
        self.uri = uri
    }
    
    public init(title: String, artistName: String?, uri: NSURL) {
        if let artistName = artistName {
            self.init(title: title, artistNames: [artistName], uri: uri)
        } else {
            self.init(title: title, artistNames: [String](), uri: uri)
        }
    }
}

public func ==(x: Song, y: Song) -> Bool {
    return x.title == y.title && x.uri == y.uri
}
