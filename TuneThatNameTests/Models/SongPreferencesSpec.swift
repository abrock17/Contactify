import TuneThatName
import Quick
import Nimble

class SongPreferencesSpec: QuickSpec {
    
    override func spec() {
        describe("equality") {
            
            it("are not equal when characteristics do not match") {
                expect(SongPreferences(characteristics: [.Popular]))
                    .toNot(equal(SongPreferences(characteristics: [.Popular, .Positive])))
            }

            it("are equal when characteristics match") {
                expect(SongPreferences(characteristics: [.Popular, .Positive]))
                    .to(equal(SongPreferences(characteristics: [.Popular, .Positive])))
            }
        }
    }
}
