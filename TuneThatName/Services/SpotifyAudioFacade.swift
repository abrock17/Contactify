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
    
    func reset(callback: SPTErrorableOperationCallback)
}

public protocol SpotifyPlaybackDelegate {
    
    func changedPlaybackStatus(isPlaying: Bool)
    
    func changedCurrentTrack(spotifyTrack: SpotifyTrack?)
}

public class SpotifyAudioFacadeImpl: NSObject, SpotifyAudioFacade {
    
    static let sharedSPTCoreAudioController = SPTCoreAudioController()
    static let sharedSPTAudioStreamingController: SPTAudioStreamingController = {
        let audioStreamingController = SPTAudioStreamingController(clientId: SpotifyAuthService.clientID, audioController: sharedSPTCoreAudioController)
        audioStreamingController.diskCache = SPTDiskCache(capacity: 67108864)
        return audioStreamingController
        }()
    
    static let sharedInstance = SpotifyAudioFacadeImpl(sptAudioStreamingController: sharedSPTAudioStreamingController, sptCoreAudioController: sharedSPTCoreAudioController, spotifyAuthService: SpotifyAuthService())

    let audioStreamingController: SPTAudioStreamingController
    let coreAudioController: SPTCoreAudioController
    let spotifyAuthService: SpotifyAuthService
    public var playbackDelegate: SpotifyPlaybackDelegate? {
        didSet {
            playbackDelegate?.changedPlaybackStatus(isPlaying)
            playbackDelegate?.changedCurrentTrack(self.currentSpotifyTrack)
        }
    }
    
    public var isPlaying = false
    public var currentSpotifyTrack: SpotifyTrack?
    
    public init(sptAudioStreamingController: SPTAudioStreamingController, sptCoreAudioController: SPTCoreAudioController, spotifyAuthService: SpotifyAuthService) {
        self.audioStreamingController = sptAudioStreamingController
        self.coreAudioController = sptCoreAudioController
        self.spotifyAuthService = spotifyAuthService
        super.init()
        self.audioStreamingController.playbackDelegate = self
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
                        self.audioStreamingController.playURIs(uris, fromIndex: Int32(index)) {
                            error in
                            callback(error)
                        }
                    }
                }
            case .Failure(let error):
                callback(error)
            case .Canceled:
                callback(NSError(domain: Constants.Error.Domain, code: Constants.Error.SpotifyLoginCanceledCode, userInfo: [NSLocalizedDescriptionKey: Constants.Error.SpotifyLoginCanceledMessage]))
            }
        }
    }
    
    func prepareToPlayInSession(session: SPTSession, callback: SPTErrorableOperationCallback) {
        coreAudioController.clearAudioBuffers()
        if !audioStreamingController.loggedIn {
            audioStreamingController.loginWithSession(session) {
                error in

                callback(error)
            }
        } else {
            callback(nil)
        }
    }
    
    public func updatePlaylist(playlist: Playlist, withIndex index: Int, callback: SPTErrorableOperationCallback) {
        audioStreamingController.replaceURIs(playlist.songURIs, withCurrentTrack: Int32(index), callback: callback)
    }
    
    public func togglePlay(callback: SPTErrorableOperationCallback) {
        audioStreamingController.setIsPlaying(!audioStreamingController.isPlaying, callback: callback)
    }
    
    public func stopPlay(callback: SPTErrorableOperationCallback) {
        audioStreamingController.stop(callback)
    }
    
    public func toNextTrack(callback: SPTErrorableOperationCallback) {
        audioStreamingController.skipNext(callback)
    }
    
    public func toPreviousTrack(callback: SPTErrorableOperationCallback) {
        audioStreamingController.skipPrevious(callback)
    }
    
    public func reset(callback: SPTErrorableOperationCallback) {
        audioStreamingController.logout() {
            error in
            
            self.audioStreaming(self.audioStreamingController, didChangePlaybackStatus: false)
            self.audioStreaming(self.audioStreamingController, didChangeToTrack: nil)
            callback(error)
        }
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
