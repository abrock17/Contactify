import TuneThatName
import Quick
import Nimble

class SpotifyUserSpec: QuickSpec {
    
    let username1 = "billy"
    let username2 = "johnny"
    let territory1 = "US"
    let territory2 = "SE"
    
    override func spec() {
        describe("equality") {
            it("is when all properties match") {
                expect(SpotifyUser(username: self.username1, territory: self.territory1))
                    .to(equal(SpotifyUser(username: self.username1, territory: self.territory1)))
            }

            it("is not when username does not match") {
                expect(SpotifyUser(username: self.username1, territory: self.territory1))
                    .toNot(equal(SpotifyUser(username: self.username2, territory: self.territory1)))
            }
            
            it("is not when territory does not match") {
                expect(SpotifyUser(username: self.username1, territory: self.territory1))
                    .toNot(equal(SpotifyUser(username: self.username1, territory: self.territory2)))
            }
        }
    }
}
