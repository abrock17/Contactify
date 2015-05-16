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
        let mockedResult = mocker.returnValueForCallTo(Method.playPlaylist)
        if let mockedResult = mockedResult as? NSError {
            callback(mockedResult)
        } else {
            callback(nil)
        }
    }
    
    func togglePlay(callback: SPTErrorableOperationCallback) {
        
    }
    
    func stopPlay(callback: SPTErrorableOperationCallback) {
        mocker.recordCall(Method.stopPlay)
        callback(nil)
    }
}
