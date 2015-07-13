import TuneThatName

class MockSpotifyAudioFacade: NSObject, SpotifyAudioFacade {
    
    let mocker = Mocker()
    
    struct Method {
        static let getPlaybackDelegate = "getPlaybackDelegate"
        static let setPlaybackDelegate = "setPlaybackDelegate"
        static let getIsPlaying = "getIsPlaying"
        static let getCurrentSpotifyTrack = "getCurrentSpotifyTrack"
        static let playPlaylist = "playPlaylist"
        static let updatePlaylist = "updatePlaylist"
        static let togglePlay = "togglePlay"
        static let stopPlay = "stopPlay"
        static let toNextTrack = "toNextTrack"
        static let toPreviousTrack = "toPreviousTrack"
    }
    
    var playbackDelegate: SpotifyPlaybackDelegate {
        get {
            if let mockedResult = mocker.mockCallTo(Method.getPlaybackDelegate) as? SpotifyPlaybackDelegate {
                return mockedResult
            } else {
                return MockSpotifyPlaybackDelegate()
            }
        }
        set {
            mocker.recordCall(Method.setPlaybackDelegate, parameters: newValue)
        }
    }
    var isPlaying: Bool {
        get {
            if let mockedResult = mocker.mockCallTo(Method.getIsPlaying) as? Bool {
                return mockedResult
            } else {
                return false
            }
        }
    }
    var currentSpotifyTrack: SpotifyTrack? {
        get {
            return mocker.mockCallTo(Method.getCurrentSpotifyTrack) as? SpotifyTrack
        }
    }
    
    func playPlaylist(playlist: Playlist, fromIndex index: Int, inSession session: SPTSession, callback: SPTErrorableOperationCallback) {
        mocker.recordCall(Method.playPlaylist, parameters: playlist, index, session)
        callback(getMockedError(Method.playPlaylist))
    }
    
    func updatePlaylist(playlist: Playlist, withIndex index: Int, callback: SPTErrorableOperationCallback) {
        mocker.recordCall(Method.updatePlaylist, parameters: playlist, index)
        callback(getMockedError(Method.updatePlaylist))
    }

    func togglePlay(callback: SPTErrorableOperationCallback) {
        mocker.recordCall(Method.togglePlay)
        callback(getMockedError(Method.togglePlay))
    }
    
    func stopPlay(callback: SPTErrorableOperationCallback) {
        mocker.recordCall(Method.stopPlay)
        callback(getMockedError(Method.stopPlay))
    }
    
    func toNextTrack(callback: SPTErrorableOperationCallback) {
        mocker.recordCall(Method.toNextTrack)
        callback(getMockedError(Method.toNextTrack))
    }
    
    func toPreviousTrack(callback: SPTErrorableOperationCallback) {
        mocker.recordCall(Method.toPreviousTrack)
        callback(getMockedError(Method.toPreviousTrack))
    }
    
    func getMockedError(method: String) -> NSError! {
        let error: NSError!
        let mockedResult = mocker.returnValueForCallTo(method)
        if let mockedResult = mockedResult as? NSError {
            error = mockedResult
        } else {
            error = nil
        }
        
        return error
    }
    
    func getMockedSpotifyTrackResult(method: String) -> SpotifyTrackResult {
        let spotifyTrackResult: SpotifyTrackResult
        let mockedResult = mocker.returnValueForCallTo(method)
        if let mockedResult = mockedResult as? SpotifyTrackResult {
            spotifyTrackResult = mockedResult
        } else {
            spotifyTrackResult = SpotifyTrackResult.Success(
                SpotifyTrack(
                    uri: NSURL(string: "un_important_mocked_uri")!,
                    name: "unimportant mocked track",
                    artistNames: [],
                    albumName: nil,
                    albumLargestCoverImageURL: nil,
                    albumSmallestCoverImageURL: nil))
        }
        
        return spotifyTrackResult
    }
}

