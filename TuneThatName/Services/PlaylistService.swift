import Foundation

public class PlaylistService {
    
    public enum PlaylistResult {
        case Success(Playlist)
        case Failure(NSError)
    }
    
    public init() {
    }
    
    public func createPlaylist(callback: PlaylistResult -> Void) {
        // retrieve contacts
        // for each contact
            // get song
            // add to playlist
        
        callback(.Success(Playlist(name: "name", uri: nil, songs: [Song(title: "title", artistName: "artistName", uri: NSURL(string: "uri"))])))
//        callback(.Failure(NSError(domain: Constants.Error.Domain, code: 999, userInfo: [NSLocalizedDescriptionKey: "something went horribly wrong"])))
    }
}