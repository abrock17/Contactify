import TuneThatName
import Quick
import Nimble

class PreferencesServiceSpec: QuickSpec {
    
    override func spec() {
        describe("The Preferences Service") {
            var preferencesService: PreferencesService!
            var mockUserDefaults: MockUserDefaults!
            let playlistPreferences = PlaylistPreferences(numberOfSongs: 999, filterContacts: false, songPreferences: SongPreferences())
            
            beforeEach() {
                mockUserDefaults = MockUserDefaults()
                preferencesService = PreferencesService(userDefaults: mockUserDefaults)
            }
            
            describe("save playlist preferences") {
                it("saves the preferences to user defaults") {
                    preferencesService.savePlaylistPreferences(playlistPreferences)
                    
                    expect(mockUserDefaults.mocker.getNthCallTo(MockUserDefaults.Method.setObject, n: 0)?[0] as? NSData).to(equal(NSKeyedArchiver.archivedDataWithRootObject(playlistPreferences)))
                    expect(mockUserDefaults.mocker.getNthCallTo(MockUserDefaults.Method.setObject, n: 0)?[1] as? String).to(equal(Constants.StorageKeys.playlistPreferences))
                }
            }
            
            describe("retrieve the playlist preferences") {
                context("when no preferences are stored in user defaults") {
                    it("returns nil") {
                        mockUserDefaults.mocker.prepareForCallTo(MockUserDefaults.Method.dataForKey, returnValue: nil)
                        
                        let retrievedPlaylistPreferences = preferencesService.retrievePlaylistPreferences()
                        
                        expect(retrievedPlaylistPreferences).to(beNil())
                    }
                }

                context("when preferences are stored in user defaults") {
                    it("returns the preferences") {
                        let playlistPreferencesData = NSKeyedArchiver.archivedDataWithRootObject(playlistPreferences)
                        mockUserDefaults.mocker.prepareForCallTo(MockUserDefaults.Method.dataForKey, returnValue: playlistPreferencesData)
                        
                        let retrievedPlaylistPreferences = preferencesService.retrievePlaylistPreferences()
                        
                        expect(retrievedPlaylistPreferences).to(equal(playlistPreferences))
                    }
                }
            }
            
            describe("get default playlist preferences") {
                it("returns the expected preferences") {
                    let expectedPlaylistPreferences = PlaylistPreferences(numberOfSongs: 10, filterContacts: false, songPreferences: SongPreferences(characteristics: Set<SongPreferences.Characteristic>([.Popular])))
                    
                    expect(preferencesService.getDefaultPlaylistPreferences()).to(equal(expectedPlaylistPreferences))
                }
            }
        }
    }
}