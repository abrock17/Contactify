import TuneThatName
import Quick
import Nimble

class SongPreferencesSpec: QuickSpec {
    
    override func spec() {
        describe("equality") {
            
            it("are not equal when favorPopular doesn't match") {
                expect(SongPreferences(favorPopular: false, favorPositive: false, favorNegative: false))
                    .toNot(equal(SongPreferences(favorPopular: true, favorPositive: false, favorNegative: false)))
            }

            it("are equal when all properties match") {
                expect(SongPreferences(favorPopular: true, favorPositive: false, favorNegative: false))
                    .to(equal(SongPreferences(favorPopular: true, favorPositive: false, favorNegative: false)))
            }
        }
    }
}
