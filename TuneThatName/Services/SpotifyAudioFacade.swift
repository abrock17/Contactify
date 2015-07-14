import Foundation

public protocol SpotifyAudioFacade: SPTAudioStreamingPlaybackDelegate {
    
    var playbackDelegate: SpotifyPlaybackDelegate { get set }
    var isPlaying: Bool { get }
    var currentSpotifyTrack: SpotifyTrack? { get }
    
    func playPlaylist(playlist: Playlist, fromIndex index: Int, inSession session: SPTSession, callback: SPTErrorableOperationCallback)
    
    func updatePlaylist(playlist: Playlist, withIndex index: Int, callback: SPTErrorableOperationCallback)
    
    func togglePlay(callback: SPTErrorableOperationCallback)
    
    func stopPlay(callback: SPTErrorableOperationCallback)
    
    func toNextTrack(callback: SPTErrorableOperationCallback)
    
    func toPreviousTrack(callback: SPTErrorableOperationCallback)
}

public enum SpotifyTrackResult {
    case Success(SpotifyTrack)
    case Failure(NSError)
}

public protocol SpotifyPlaybackDelegate {
    
    func changedPlaybackStatus(isPlaying: Bool)
    
    func changedCurrentTrack(spotifyTrack: SpotifyTrack?)
}

public class SpotifyAudioFacadeImpl: NSObject, SpotifyAudioFacade {
    
    static let sharedSpotifyAudioController: SPTAudioStreamingController = {
        let spotifyAudioController = SPTAudioStreamingController(clientId: SpotifyService.clientID)
        spotifyAudioController.diskCache = SPTDiskCache(capacity: 67108864)
        return spotifyAudioController
        }()

    let spotifyAudioController: SPTAudioStreamingController
    public var playbackDelegate: SpotifyPlaybackDelegate
    
    public var isPlaying = false
    public var currentSpotifyTrack: SpotifyTrack?
    
    public init(
        spotifyAudioController: SPTAudioStreamingController = sharedSpotifyAudioController,
        spotifyPlaybackDelegate: SpotifyPlaybackDelegate) {
            self.spotifyAudioController = spotifyAudioController
            self.playbackDelegate = spotifyPlaybackDelegate
            super.init()
            self.spotifyAudioController.playbackDelegate = self
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
    
    public func audioStreaming(audioStreaming: SPTAudioStreamingController!, didChangePlaybackStatus isPlaying: Bool) {
        self.isPlaying = isPlaying
        playbackDelegate.changedPlaybackStatus(isPlaying)
    }
    
    public func audioStreaming(audioStreaming: SPTAudioStreamingController!, didChangeToTrack trackMetadata: [NSObject : AnyObject]!) {
        if trackMetadata != nil {
            if let uriString = trackMetadata["SPTAudioStreamingMetadataTrackURI"] as? String, uri = NSURL(string: uriString) {
                SPTTrack.trackWithURI(uri, session: nil) {
                    (error, result) in
                    
                    if error != nil {
                        println("Error retrieving current track: \(error)")
                    }
                    let sptTrack = result as? SPTTrack
                    self.currentSpotifyTrack = sptTrack != nil ? SpotifyTrack(sptTrack: sptTrack!) : nil
                    self.playbackDelegate.changedCurrentTrack(self.currentSpotifyTrack)
                }
            }
        } else {
            self.currentSpotifyTrack = nil
            self.playbackDelegate.changedCurrentTrack(self.currentSpotifyTrack)
        }
    }
}
