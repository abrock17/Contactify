import TuneThatName

class MockSpotifyAudioFacade: SpotifyAudioFacade {
    
    let mocker = Mocker()
    
    struct Method {
        static let playPlaylist = "playPlaylist"
        static let togglePlay = "togglePlay"
        static let stopPlay = "stopPlay"
        static let getTrackWithURI = "getTrackWithURI"
        static let getCurrentTrackInSession = "getCurrentTrackInSession"
    }
    
    func playPlaylist(playlist: Playlist, fromIndex index: Int, inSession session: SPTSession, callback: SPTErrorableOperationCallback) {
        mocker.recordCall(Method.playPlaylist, parameters: playlist, index, session)
        callback(getMockedError(Method.playPlaylist))
    }
    
    func togglePlay(callback: SPTErrorableOperationCallback) {
        mocker.recordCall(Method.togglePlay)
        callback(getMockedError(Method.togglePlay))
    }
    
    func stopPlay(callback: SPTErrorableOperationCallback) {
        mocker.recordCall(Method.stopPlay)
        callback(getMockedError(Method.stopPlay))
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
    
    func getTrackWithURI(uri: NSURL, inSession session: SPTSession, callback: SpotifyTrackResult -> Void) {
        mocker.recordCall(Method.getTrackWithURI, parameters: uri, session)
        callback(getMockedSpotifyTrackResult(Method.getTrackWithURI))
    }
    
    func getCurrentTrackInSession(session: SPTSession, callback: SpotifyTrackResult -> Void) {
        mocker.recordCall(Method.getCurrentTrackInSession, parameters: session)
        callback(getMockedSpotifyTrackResult(Method.getCurrentTrackInSession))
    }
    
    func getMockedSpotifyTrackResult(method: String) -> SpotifyTrackResult {
        let spotifyTrackResult: SpotifyTrackResult
        let mockedResult = mocker.returnValueForCallTo(Method.getCurrentTrackInSession)
        if let mockedResult = mockedResult as? SpotifyTrackResult {
            spotifyTrackResult = mockedResult
        } else {
            spotifyTrackResult = SpotifyTrackResult.Success(
                SpotifyTrack(
                    uri: nil,
                    name: "unimportant mocked track",
                    artistNames: [],
                    albumName: nil,
                    albumLargestCoverImageURL: nil,
                    albumSmallestCoverImageURL: nil))
        }
        
        return spotifyTrackResult
    }
}
