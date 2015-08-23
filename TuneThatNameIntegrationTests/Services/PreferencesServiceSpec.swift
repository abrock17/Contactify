import TuneThatName
import Quick
import Nimble

class PreferencesServiceSpec: QuickSpec {
    
    override func spec() {
        describe("PreferencesService") {
            var preferencesService: PreferencesService!
            var existingPlaylistPreferences: PlaylistPreferences?
            
            beforeEach() {
                preferencesService = PreferencesService()
                existingPlaylistPreferences = preferencesService.retrievePlaylistPreferences()
            }
            
            afterEach() {
                if let preferencesToSave = existingPlaylistPreferences {
                    preferencesService.savePlaylistPreferences(preferencesToSave)
                }
            }
            
            describe("retrieve playlist preferences") {
                context("when they have been previously saved") {
                    it("can retrieve them") {
                        let playlistPreferences = PlaylistPreferences(numberOfSongs: 3, filterContacts: true, songPreferences: SongPreferences(characteristics: [.Popular, .Negative, .Chill]))
                        
                        preferencesService.savePlaylistPreferences(playlistPreferences)
                        
                        let retrievedPreferences = preferencesService.retrievePlaylistPreferences()
                        
                        expect(retrievedPreferences).to(equal(playlistPreferences))
                    }
                }
            }
        }
    }
}