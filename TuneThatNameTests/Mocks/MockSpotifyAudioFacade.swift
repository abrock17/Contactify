import TuneThatName

class MockSpotifyAudioFacade: SpotifyAudioFacade {
    
    let mocker = Mocker()
    
    struct Method {
        static let playPlaylist = "playPlaylist"
        static let togglePlay = "togglePlay"
        static let stopPlay = "stopPlay"
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
    
    func getCurrentTrackInSession(session: SPTSession, callback: SPTRequestCallback) {
        callback(nil, nil)
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
}
