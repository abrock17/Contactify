import TuneThatName
import Quick
import Nimble

class SongPreferencesSpec: QuickSpec {
    
    override func spec() {
        describe("equality") {
            
            it("are not equal when favorPopular doesn't match") {
                expect(SongPreferences(favorPopular: false)).toNot(equal(SongPreferences(favorPopular: true)))
            }

            it("are equal when favorPopular matches") {
                expect(SongPreferences(favorPopular: true)).to(equal(SongPreferences(favorPopular: true)))
            }
        }
    }
}
