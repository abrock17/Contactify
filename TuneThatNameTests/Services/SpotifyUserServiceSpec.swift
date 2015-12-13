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
            var mockSpotifyAuthService: MockSpotifyAuthService!
            
            beforeEach() {
                self.callbackSptUser = nil
                self.callbackError = nil
                
                mockSpotifyAuthService = MockSpotifyAuthService()
                spotifyUserService = SpotifyUserService(spotifyAuthService: mockSpotifyAuthService)
            }
            
            describe("retrieve current user") {
                
                context("when the auth service calls back with an error") {
                    let error = NSError(domain: "com.spotify.ios", code: 9876, userInfo: [NSLocalizedDescriptionKey: "error logging in"])
                    
                    it("calls back with the error") {
                        mockSpotifyAuthService.mocker.prepareForCallTo(MockSpotifyAuthService.Method.doWithSession, returnValue: SpotifyAuthService.AuthResult.Failure(error))
                        
                        spotifyUserService.retrieveCurrentUser(self.sptUserCallback)
                        
                        expect(self.callbackError).to(equal(error))
                        expect(self.callbackSptUser).to(beNil())
                    }
                }
                
                context("when the auth service calls back with canceled") {
                    it("calls back with the expected error") {
                        mockSpotifyAuthService.mocker.prepareForCallTo(MockSpotifyAuthService.Method.doWithSession, returnValue: SpotifyAuthService.AuthResult.Canceled)
                        
                        spotifyUserService.retrieveCurrentUser(self.sptUserCallback)
                        
                        expect(self.callbackError).to(equal(NSError(domain: Constants.Error.Domain, code: Constants.Error.SpotifyLoginCanceledCode,
                            userInfo: [NSLocalizedDescriptionKey: Constants.Error.SpotifyLoginCanceledMessage])))
                        expect(self.callbackSptUser).to(beNil())
                    }
                }
            }
        }
    }
}