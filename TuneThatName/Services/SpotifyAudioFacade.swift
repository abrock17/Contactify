import Foundation

public protocol SpotifyAudioFacade {
    
    func playPlaylist(playlist: Playlist, fromIndex index: Int, inSession session: SPTSession, callback: SPTErrorableOperationCallback)
    
    func updatePlaylist(playlist: Playlist, withIndex index: Int, callback: SPTErrorableOperationCallback)
    
    func togglePlay(callback: SPTErrorableOperationCallback)
    
    func stopPlay(callback: SPTErrorableOperationCallback)
    
    func toNextTrack(callback: SPTErrorableOperationCallback)
    
    func toPreviousTrack(callback: SPTErrorableOperationCallback)
    
    func getTrackWithURI(uri: NSURL, inSession session: SPTSession, callback: SpotifyTrackResult -> Void)
    
    func getCurrentTrackInSession(session: SPTSession, callback: SpotifyTrackResult -> Void)
}

public enum SpotifyTrackResult {
    case Success(SpotifyTrack)
    case Failure(NSError)
}

public class SpotifyAudioFacadeImpl: SpotifyAudioFacade {
    
    static let sharedSpotifyAudioController: SPTAudioStreamingController = {
        let spotifyAudioController = SPTAudioStreamingController(clientId: SpotifyService.clientID)
        spotifyAudioController.diskCache = SPTDiskCache(capacity: 67108864)
        return spotifyAudioController
        }()

    let spotifyAudioController: SPTAudioStreamingController
    
    public init(
        spotifyAudioController: SPTAudioStreamingController = sharedSpotifyAudioController,
        spotifyPlaybackDelegate: SPTAudioStreamingPlaybackDelegate) {
        self.spotifyAudioController = spotifyAudioController
        self.spotifyAudioController.playbackDelegate = spotifyPlaybackDelegate
    }
    
    public func playPlaylist(playlist: Playlist, fromIndex index: Int, inSession session: SPTSession, callback: SPTErrorableOperationCallback) {
        prepareToPlayInSession(session) {
            error in
            if error != nil {
                callback(error)
            } else {
                self.spotifyAudioController.playURIs(playlist.songURIs, fromIndex: Int32(index)) {
                    error in
                    callback(error)
                }
            }
        }
    }
    
    func prepareToPlayInSession(session: SPTSession, callback: SPTErrorableOperationCallback) {
        if !spotifyAudioController.loggedIn {
            spotifyAudioController.loginWithSession(session) {
                error in
                if error != nil {
                    callback(error)
                } else {
                    self.resetIsPlaying(callback)
                }
            }
        } else {
            resetIsPlaying(callback)
        }
    }
    
    func resetIsPlaying(callback: SPTErrorableOperationCallback) {
        if self.spotifyAudioController.isPlaying {
            spotifyAudioController.setIsPlaying(false) {
                error in
                if error != nil {
                    callback(error)
                } else {
                    self.spotifyAudioController.setIsPlaying(true) {
                        error in
                        callback(error)
                    }
                }
            }
        } else {
            callback(nil)
        }
    }
    
    public func updatePlaylist(playlist: Playlist, withIndex index: Int, callback: SPTErrorableOperationCallback) {
        spotifyAudioController.replaceURIs(playlist.songURIs, withCurrentTrack: Int32(index), callback: callback)
    }
    
    public func togglePlay(callback: SPTErrorableOperationCallback) {
        spotifyAudioController.setIsPlaying(!spotifyAudioController.isPlaying, callback: callback)
    }
    
    public func stopPlay(callback: SPTErrorableOperationCallback) {
        spotifyAudioController.stop(callback)
    }
    
    public func toNextTrack(callback: SPTErrorableOperationCallback) {
        spotifyAudioController.skipNext(callback)
    }
    
    public func toPreviousTrack(callback: SPTErrorableOperationCallback) {
        spotifyAudioController.skipPrevious(callback)
    }
    
    public func getTrackWithURI(uri: NSURL, inSession session: SPTSession, callback: SpotifyTrackResult -> Void) {
        SPTTrack.trackWithURI(uri, session: session) {
            (error, result) in
            
            if error != nil {
                callback(.Failure(error))
            } else {
                callback(.Success(SpotifyTrack(sptTrack: result as! SPTTrack)))
            }
        }
    }
    
    public func getCurrentTrackInSession(session: SPTSession, callback: SpotifyTrackResult -> Void) {
        if spotifyAudioController.currentTrackURI != nil {
            getTrackWithURI(self.spotifyAudioController.currentTrackURI, inSession: session, callback: callback)
        } else {
            callback(.Failure(NSError(domain: Constants.Error.Domain, code: Constants.Error.SpotifyNoCurrentTrackCode, userInfo: [NSLocalizedDescriptionKey: Constants.Error.SpotifyNoCurrentTrackMessage])))
        }
    }
}
