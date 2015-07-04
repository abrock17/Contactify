import Foundation

public struct SpotifyTrack {

    public let uri: NSURL!
    public let name: String!
    public let artistNames: [String]!
    public var displayArtistName: String! {
        return Song.formattedDisplayNameForArtistNames(self.artistNames)
    }
    public let albumName: String!
    public let albumLargestCoverImageURL: NSURL!
    public let albumSmallestCoverImageURL: NSURL!

    public init(uri: NSURL!, name: String!, artistNames: [String]!, albumName: String!, albumLargestCoverImageURL: NSURL!, albumSmallestCoverImageURL: NSURL!) {
        self.uri = uri
        self.name = name
        self.artistNames = artistNames
        self.albumName = albumName
        self.albumLargestCoverImageURL = albumLargestCoverImageURL
        self.albumSmallestCoverImageURL = albumSmallestCoverImageURL
    }
    
    public init(sptTrack: SPTTrack) {
        self.init(
            uri: sptTrack.uri,
            name: sptTrack.name,
            artistNames: sptTrack.artists.map{ $0.name },
            albumName: sptTrack.album.name,
            albumLargestCoverImageURL: sptTrack.album.largestCover.imageURL,
            albumSmallestCoverImageURL: sptTrack.album.smallestCover.imageURL
        )
    }
}