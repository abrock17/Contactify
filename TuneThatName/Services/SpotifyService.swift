import Foundation

public class SpotifyService {
    
    let trackMaxBatchSize = 100
    
    public enum PlaylistResult {
        case Success(Playlist)
        case Failure(NSError)
    }
    
    public init() {
    }
    
    public class func initializeDefaultSPTAuth() {
        let auth = SPTAuth.defaultInstance()
        auth.clientID = "02b72a9ba42742acbebb0d3277c9996f"
        auth.requestedScopes = [SPTAuthPlaylistModifyPublicScope, SPTAuthPlaylistModifyPrivateScope, SPTAuthStreamingScope]
        auth.redirectURL = NSURL(string: "name-playlist-creator-login://return")
        auth.tokenSwapURL = NSURL(string: "https://name-playlist-spt-token-swap.herokuapp.com/swap")
        auth.tokenRefreshURL = NSURL(string: "https://name-playlist-spt-token-swap.herokuapp.com/refresh")
        auth.sessionUserDefaultsKey = "SpotifySessionData"
    }
    
    public func savePlaylist(playlist: Playlist!, session: SPTSession!, callback: (PlaylistResult) -> Void) {
        SPTRequest.playlistsForUserInSession(session) {
            (error, playlists) in

            if error != nil {
                callback(.Failure(error))
            } else if let playlists = playlists as? SPTPlaylistList {
                self.createPlaylist(playlist, inPlaylistList: playlists, withSession: session, callback: callback)
            } else {
                self.errorForMessage("Unable to retrieve users playlists", andFailureReason: "List of SPTPlaylists from Spotify was nil")
            }
        }
    }
    
    func createPlaylist(playlist: Playlist!, inPlaylistList playlists: SPTPlaylistList!, withSession session: SPTSession!, callback: (PlaylistResult) -> Void) {
        playlists.createPlaylistWithName(playlist.name, publicFlag: false, session: session) {
            (error, editablePlaylist) in
            
            if error != nil {
                callback(.Failure(error))
            } else {
                var trackURIs = [NSURL]()
                for song in playlist.songs {
                    trackURIs.append(song.uri!)
                }
                SPTTrack.tracksWithURIs(trackURIs, session: session) {
                    (error, tracks) in
                    
                    if error != nil {
                        callback(.Failure(error))
                    } else if let tracks = tracks as? [SPTTrack] {
                        self.addTracks(tracks, startingAtIndex: 0, toPlaylistSnapshot: editablePlaylist, withSession: session, callback: callback)
                    }
                }
            }
        }
    }
    
    func addTracks(tracks: [SPTTrack], startingAtIndex startIndex: Int, toPlaylistSnapshot playlistSnapshot: SPTPlaylistSnapshot, withSession session: SPTSession, callback: (PlaylistResult) -> Void) {
        
        if moreTracksToAdd(trackIndex: startIndex, tracks: tracks) {
            let endIndex = (startIndex + trackMaxBatchSize) < tracks.endIndex ? startIndex + trackMaxBatchSize : tracks.endIndex
            let tracksSlice = tracks[startIndex..<endIndex]
            
            playlistSnapshot.addTracksToPlaylist(Array(tracksSlice), withSession: session) {
                error in
                
                if error != nil {
                    callback(.Failure(error))
                } else {
                    self.addTracks(tracks, startingAtIndex: endIndex, toPlaylistSnapshot: playlistSnapshot, withSession: session, callback: callback)
                }
            }
        } else {
            callback(.Success(buildPlaylistFromTracks(tracks, playlistSnapshot: playlistSnapshot)))
        }
    }
    
    func moreTracksToAdd(#trackIndex: Int, tracks: [SPTTrack]) -> Bool {
        return trackIndex < tracks.endIndex
    }
    
    func buildPlaylistFromTracks(tracks: [SPTTrack], playlistSnapshot: SPTPlaylistSnapshot) -> Playlist {
        var songs = [Song]()
        for track in tracks {
            songs.append(Song(title: track.name, artistName: buildArtistNameString(track.artists), uri: track.uri))
        }
        return Playlist(name: playlistSnapshot.name, uri: playlistSnapshot.uri, songs: songs)
    }
    
    public func retrievePlaylist(uri: NSURL!, session: SPTSession!, callback: (PlaylistResult) -> Void) {
        SPTPlaylistSnapshot.playlistWithURI(uri, session: session) {
            (error, playlistSnapshot) in
            
            if error != nil {
                callback(.Failure(error))
            } else if let playlistSnapshot = playlistSnapshot as? SPTPlaylistSnapshot {
                var playlist = Playlist(name: playlistSnapshot.name, uri: playlistSnapshot.uri)
                
                self.completePlaylistRetrieval(playlist, withPlaylistSnapshotPage: playlistSnapshot.firstTrackPage, withSession: session, callback: callback)
            }
        }
    }
    
    func completePlaylistRetrieval(var playlist: Playlist!, withPlaylistSnapshotPage page: SPTListPage!, withSession session: SPTSession!, callback: (PlaylistResult) -> Void) {
        if let tracks = page.items {
            for track in tracks {
                playlist.songs.append(Song(title: track.name, artistName: buildArtistNameString(track.artists), uri: track.uri))
            }
        }
        
        if page.hasNextPage {
            page.requestNextPageWithSession(session) {
                (error, nextPage) in
                if error != nil {
                    callback(.Failure(error))
                } else if let nextPage = nextPage as? SPTListPage {
                    self.completePlaylistRetrieval(playlist, withPlaylistSnapshotPage: nextPage, withSession: session, callback: callback)
                } else {
                    self.errorForMessage("Unable to retrieve playlist", andFailureReason: "SPTPlaylistSnapshot page from Spotify was nil")
                }
            }
        } else {
            callback(.Success(playlist))
        }
    }
    
    func buildArtistNameString(artists: [AnyObject]) -> String? {
        var artistNames = [String]()
        for artist in artists {
            if let artistName = (artist as? SPTPartialArtist)?.name {
                artistNames.append(artistName)
            }
        }
        
        return ", ".join(artistNames)
    }
    
    func errorForMessage(message: String, andFailureReason reason: String) -> NSError {
        return NSError(domain: Constants.Error.Domain, code: 0, userInfo: [NSLocalizedDescriptionKey: message, NSLocalizedFailureReasonErrorKey: reason])
    }
}
