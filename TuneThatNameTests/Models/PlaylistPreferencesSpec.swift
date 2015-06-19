import TuneThatName
import Quick
import Nimble

class PlaylistPreferencesSpec: QuickSpec {
    
    override func spec() {
        describe("equality") {
            
            it("are not equal when numberOfSongs don't match") {
                expect(
                    PlaylistPreferences(numberOfSongs: 1, filterContacts: false, songPreferences: SongPreferences(favorPopular: true)))
                    .toNot(equal(
                        PlaylistPreferences(numberOfSongs: 2, filterContacts: false, songPreferences: SongPreferences(favorPopular: true))))
            }
            
            it("are not equal when filterContacts doesn't match") {
                expect(
                    PlaylistPreferences(numberOfSongs: 1, filterContacts: false, songPreferences: SongPreferences(favorPopular: true)))
                    .toNot(equal(
                        PlaylistPreferences(numberOfSongs: 1, filterContacts: true, songPreferences: SongPreferences(favorPopular: true))))
            }
            
            it("are not equal when songPreferences don't match") {
                expect(
                    PlaylistPreferences(numberOfSongs: 1, filterContacts: false, songPreferences: SongPreferences(favorPopular: true)))
                    .toNot(equal(
                        PlaylistPreferences(numberOfSongs: 1, filterContacts: false, songPreferences: SongPreferences(favorPopular: false))))
            }
            
            it("are equal when all properties match") {
                expect(
                    PlaylistPreferences(numberOfSongs: 1, filterContacts: false, songPreferences: SongPreferences(favorPopular: true)))
                    .to(equal(
                        PlaylistPreferences(numberOfSongs: 1, filterContacts: false, songPreferences: SongPreferences(favorPopular: true))))
            }
        }
    }
}
