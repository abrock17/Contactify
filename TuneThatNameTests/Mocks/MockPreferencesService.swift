import TuneThatName

class MockPreferencesService: PreferencesService {
    
    struct Method {
        static let retrievePlaylistPreferences = "retrievePlaylistPreferences"
        static let savePlaylistPreferences = "savePlaylistPreferences"
    }

    let mocker = Mocker()
    
    override func retrievePlaylistPreferences() -> PlaylistPreferences? {
        return mocker.mockCallTo(Method.retrievePlaylistPreferences) as? PlaylistPreferences
    }
    
    override func savePlaylistPreferences(playlistPreferences: PlaylistPreferences) {
        mocker.recordCall(Method.savePlaylistPreferences, parameters: playlistPreferences)
    }
}