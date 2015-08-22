import TuneThatName
import Quick
import Nimble

class PlaylistPreferencesSpec: QuickSpec {
    
    override func spec() {
        describe("equality") {
            
            it("are not equal when numberOfSongs don't match") {
                expect(
                    PlaylistPreferences(numberOfSongs: 1, filterContacts: false, songPreferences: SongPreferences()))
                    .toNot(equal(
                        PlaylistPreferences(numberOfSongs: 2, filterContacts: false, songPreferences: SongPreferences())))
            }
            
            it("are not equal when filterContacts doesn't match") {
                expect(
                    PlaylistPreferences(numberOfSongs: 1, filterContacts: false, songPreferences: SongPreferences()))
                    .toNot(equal(
                        PlaylistPreferences(numberOfSongs: 1, filterContacts: true, songPreferences: SongPreferences())))
            }
            
            it("are not equal when songPreferences don't match") {
                expect(
                    PlaylistPreferences(numberOfSongs: 1, filterContacts: false,
                        songPreferences: SongPreferences(characteristics: Set<SongPreferences.Characteristic>([.Popular, .Positive]))))
                    .toNot(equal(
                        PlaylistPreferences(numberOfSongs: 1, filterContacts: false,
                            songPreferences: SongPreferences(characteristics: Set<SongPreferences.Characteristic>([.Negative])))))
            }
            
            it("are equal when all properties match") {
                expect(
                    PlaylistPreferences(numberOfSongs: 1, filterContacts: false,
                        songPreferences: SongPreferences(characteristics: Set<SongPreferences.Characteristic>([.Popular]))))
                    .to(equal(
                        PlaylistPreferences(numberOfSongs: 1, filterContacts: false,
                            songPreferences: SongPreferences(characteristics: Set<SongPreferences.Characteristic>([.Popular])))))
            }
        }
    }
}
