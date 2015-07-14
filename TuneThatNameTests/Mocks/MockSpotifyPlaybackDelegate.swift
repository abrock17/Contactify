import TuneThatName

class MockSpotifyPlaybackDelegate: SpotifyPlaybackDelegate {
    
    let mocker = Mocker()
    
    struct Method {
        static let changedCurrentTrack = "changedCurrentTrack"
        static let changedPlaybackStatus = "changedPlaybackStatus"
    }
    
    func changedPlaybackStatus(isPlaying: Bool) {
        mocker.recordCall(Method.changedPlaybackStatus, parameters: isPlaying)
    }
    
    func changedCurrentTrack(spotifyTrack: SpotifyTrack?) {
        mocker.recordCall(Method.changedCurrentTrack, parameters: spotifyTrack)
    }
}