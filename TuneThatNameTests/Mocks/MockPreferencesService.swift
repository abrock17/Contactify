import TuneThatName

class MockPreferencesService: PreferencesService {
    
    struct Method {
        static let getDefaultPlaylistPreferences = "getDefaultPlaylistPreferences"
        static let retrievePlaylistPreferences = "retrievePlaylistPreferences"
        static let savePlaylistPreferences = "savePlaylistPreferences"
        static let hasPresentedInitialHelp = "hasPresentedInitialHelp"
        static let savePresentedInitialHelp = "savePresentedInitialHelp"
    }

    let mocker = Mocker()
    
    override func getDefaultPlaylistPreferences() -> PlaylistPreferences {
        return mocker.mockCallTo(Method.getDefaultPlaylistPreferences) as! PlaylistPreferences
    }
    
    override func retrievePlaylistPreferences() -> PlaylistPreferences? {
        return mocker.mockCallTo(Method.retrievePlaylistPreferences) as? PlaylistPreferences
    }
    
    override func savePlaylistPreferences(playlistPreferences: PlaylistPreferences) {
        mocker.recordCall(Method.savePlaylistPreferences, parameters: playlistPreferences)
    }
    
    override func hasPresentedInitialHelp() -> Bool {
        mocker.recordCall(Method.hasPresentedInitialHelp)
        return mocker.returnValueForCallTo(Method.hasPresentedInitialHelp) as! Bool
    }
    
    override func savePresentedInitialHelp(helpPresented: Bool) {
        mocker.recordCall(Method.savePresentedInitialHelp, parameters: helpPresented)
    }
}