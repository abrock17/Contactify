import TuneThatName
import Quick
import Nimble

class SpotifyUserServiceSpec: QuickSpec {
    
    var callbackSptUser: SPTUser?
    var callbackError: NSError?
    
    func sptUserCallback(territoryResult: SpotifyUserService.UserResult) {
        switch (territoryResult) {
        case .Success(let sptUser):
            callbackSptUser = sptUser
        case .Failure(let error):
            callbackError = error
        }
    }
    
    override func spec() {
        describe("SpotifyUserService") {
            var spotifyUserService: SpotifyUserService!
            
            beforeEach() {
                self.callbackSptUser = nil
                self.callbackError = nil
                
                spotifyUserService = SpotifyUserService()
            }
            
            describe("retrieve the current user territory") {
                it("calls back with the expected country code") {
                    spotifyUserService.retrieveCurrentUser(self.sptUserCallback)
                    
                    expect(self.callbackSptUser?.canonicalUserName).toEventually(equal("abrock17"))
                    expect(self.callbackSptUser?.territory).toEventually(equal("US"))
                    expect(self.callbackError).to(beNil())
                }
            }
        }
    }
}