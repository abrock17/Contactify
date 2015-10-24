import Foundation

public protocol SpotifyAudioFacade: SPTAudioStreamingPlaybackDelegate {
    
    var playbackDelegate: SpotifyPlaybackDelegate? { get set }
    var isPlaying: Bool { get }
    var currentSpotifyTrack: SpotifyTrack? { get }

    func playTracksForURIs(uris: [NSURL], fromIndex index: Int, callback: SPTErrorableOperationCallback)
    
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
        let spotifyAudioController = SPTAudioStreamingController(clientId: SpotifyAuthService.clientID)
        spotifyAudioController.diskCache = SPTDiskCache(capacity: 67108864)
        return spotifyAudioController
        }()
    
    static let sharedInstance = SpotifyAudioFacadeImpl(spotifyAudioController: sharedSpotifyAudioController, spotifyAuthService: SpotifyAuthService())

    let spotifyAudioController: SPTAudioStreamingController
    let spotifyAuthService: SpotifyAuthService
    public var playbackDelegate: SpotifyPlaybackDelegate? {
        didSet {
            playbackDelegate?.changedPlaybackStatus(isPlaying)
            playbackDelegate?.changedCurrentTrack(self.currentSpotifyTrack)
        }
    }
    
    public var isPlaying = false
    public var currentSpotifyTrack: SpotifyTrack?
    
    public init(spotifyAudioController: SPTAudioStreamingController, spotifyAuthService: SpotifyAuthService) {
            self.spotifyAudioController = spotifyAudioController
            self.spotifyAuthService = spotifyAuthService
            super.init()
            self.spotifyAudioController.playbackDelegate = self
    }
    
    public func playTracksForURIs(uris: [NSURL], fromIndex index: Int, callback: SPTErrorableOperationCallback) {
        spotifyAuthService.doWithSession() {
            authResult in
            
            switch (authResult) {
            case .Success(let spotifySession):
                self.prepareToPlayInSession(spotifySession) {
                    error in
                    if error != nil {
                        callback(error)
                    } else {
                        self.spotifyAudioController.playURIs(uris, fromIndex: Int32(index)) {
                            error in
                            callback(error)
                        }
                    }
                }
            case .Failure(let error):
                callback(error)
            case .Canceled:
                callback(nil)
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
        playbackDelegate?.changedPlaybackStatus(isPlaying)
    }
    
    public func audioStreaming(audioStreaming: SPTAudioStreamingController!, didChangeToTrack trackMetadata: [NSObject : AnyObject]!) {
        if trackMetadata != nil {
            if let uriString = trackMetadata["SPTAudioStreamingMetadataTrackURI"] as? String, uri = NSURL(string: uriString) {
                SPTTrack.trackWithURI(uri, session: nil) {
                    (error, result) in
                    
                    if error != nil {
                        print("Error retrieving current track: \(error)")
                    }
                    let sptTrack = result as? SPTTrack
                    self.currentSpotifyTrack = sptTrack != nil ? SpotifyTrack(sptTrack: sptTrack!) : nil
                    self.playbackDelegate?.changedCurrentTrack(self.currentSpotifyTrack)
                }
            }
        } else {
            self.currentSpotifyTrack = nil
            self.playbackDelegate?.changedCurrentTrack(self.currentSpotifyTrack)
        }
    }
}
