import Foundation

public class SpotifyAudioService {

    static let sharedSpotifyAudioController: SPTAudioStreamingController = {
        let spotifyAudioController = SPTAudioStreamingController(clientId: SpotifyService.clientID)
        spotifyAudioController.diskCache = SPTDiskCache(capacity: 67108864)
        return spotifyAudioController
        }()

    let spotifyAudioController: SPTAudioStreamingController
    
    public init(spotifyAudioController: SPTAudioStreamingController = SpotifyAudioService.sharedSpotifyAudioController, spotifyPlaybackDelegate: SPTAudioStreamingPlaybackDelegate) {
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
    
    public func getCurrentTrackURI() -> NSURL! {
        return spotifyAudioController.currentTrackURI
    }
    
    public func togglePlay(callback: SPTErrorableOperationCallback) {
        spotifyAudioController.setIsPlaying(!spotifyAudioController.isPlaying) {
            error in
            callback(error)
        }
    }
    
    public func stopPlay(callback: SPTErrorableOperationCallback) {
        spotifyAudioController.stop() {
            error in
            callback(error)
        }
    }
}
