import TuneThatName

class MockSpotifyAudioFacade: SpotifyAudioFacade {
    
    let mocker = Mocker()
    
    struct Method {
        static let stopPlay = "stopPlay"
    }
    
    func playPlaylist(playlist: Playlist, fromIndex index: Int, inSession session: SPTSession, callback: SPTErrorableOperationCallback) {
        
    }
    
    func togglePlay(callback: SPTErrorableOperationCallback) {
        
    }
    
    func stopPlay(callback: SPTErrorableOperationCallback) {
        mocker.recordCall(Method.stopPlay)
        callback(nil)
    }
}
