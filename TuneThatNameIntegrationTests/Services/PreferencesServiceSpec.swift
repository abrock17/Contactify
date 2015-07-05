import TuneThatName
import Quick
import Nimble

class PreferencesServiceSpec: QuickSpec {
    
    override func spec() {
        describe("PreferencesService") {
            var preferencesService: PreferencesService!
            
            beforeEach() {
                preferencesService = PreferencesService()
            }
            
            describe("retrieve playlist preferences") {
                context("when they have been previously saved") {
                    it("can retrieve them") {
                        let playlistPreferences = PlaylistPreferences(numberOfSongs: 3, filterContacts: true, songPreferences: SongPreferences(favorPopular: true))
                        
                        preferencesService.savePlaylistPreferences(playlistPreferences)
                        
                        let retrievedPreferences = preferencesService.retrievePlaylistPreferences()
                        
                        expect(retrievedPreferences).to(equal(playlistPreferences))
                    }
                }
            }
        }
    }
}