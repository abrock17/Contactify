import TuneThatName

class MockSpotifyPlaybackDelegate: SpotifyPlaybackDelegate {
    
    let mocker = Mocker()
    
    struct Method {
        static let changedPlaybackStatus = "changedPlaybackStatus"
        static let startedPlayingSpotifyTrack = "startedPlayingSpotifyTrack"
    }
    
    func changedPlaybackStatus(isPlaying: Bool) {
        mocker.recordCall(Method.changedPlaybackStatus, parameters: isPlaying)
    }
    
    func startedPlayingSpotifyTrack(spotifyTrack: SpotifyTrack?) {
        mocker.recordCall(Method.startedPlayingSpotifyTrack, parameters: spotifyTrack)
    }
}