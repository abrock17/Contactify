import TuneThatName
import Quick
import Nimble

class SpotifyUserServiceSpec: QuickSpec {
    
    var callbackSpotifyUser: SpotifyUser?
    var callbackError: NSError?
    
    func sptUserCallback(userResult: SpotifyUserService.UserResult) {
        switch (userResult) {
        case .Success(let spotifyUser):
            callbackSpotifyUser = spotifyUser
        case .Failure(let error):
            callbackError = error
        }
    }
    
    override func spec() {
        describe("SpotifyUserService") {
            var spotifyUserService: SpotifyUserService!
            var mockSpotifyAuthService: MockSpotifyAuthService!
            var mockUserDefaults: MockUserDefaults!
            
            let spotifyUser = SpotifyUser(username: "some_guy", territory: "ZZ")
            let spotifyUserData = NSKeyedArchiver.archivedDataWithRootObject(spotifyUser)
            
            beforeEach() {
                self.callbackSpotifyUser = nil
                self.callbackError = nil
                
                mockSpotifyAuthService = MockSpotifyAuthService()
                mockUserDefaults = MockUserDefaults()
                spotifyUserService = SpotifyUserService(spotifyAuthService: mockSpotifyAuthService,
                    userDefaults: mockUserDefaults)
            }
            
            describe("retrieve current user") {
                it("attempts to get a cached user") {
                    mockUserDefaults.mocker.prepareForCallTo(MockUserDefaults.Method.dataForKey, returnValue: spotifyUserData)
                    
                    spotifyUserService.retrieveCurrentUser(self.sptUserCallback)

                    expect(mockUserDefaults.mocker.getNthCallTo(MockUserDefaults.Method.dataForKey, n: 0)?.first as? String).to(equal(Constants.StorageKeys.spotifyCurrentUser))
                }
                
                context("when user is cached") {
                    it("returns the cached user") {
                        mockUserDefaults.mocker.prepareForCallTo(MockUserDefaults.Method.dataForKey, returnValue: spotifyUserData)
                        
                        spotifyUserService.retrieveCurrentUser(self.sptUserCallback)
                        
                        expect(self.callbackSpotifyUser).to(equal(spotifyUser))
                        expect(self.callbackError).to(beNil())
                    }
                }
                
                context("when the user is not cached") {
                    beforeEach() {
                        mockUserDefaults.mocker.prepareForCallTo(MockUserDefaults.Method.dataForKey, returnValue: nil)
                    }
                    
                    it("calls the auth service") {
                        mockSpotifyAuthService.mocker.prepareForCallTo(MockSpotifyAuthService.Method.doWithSession, returnValue: SpotifyAuthService.AuthResult.Canceled)

                        spotifyUserService.retrieveCurrentUser(self.sptUserCallback)

                        expect(mockSpotifyAuthService.mocker.getCallCountFor(MockSpotifyAuthService.Method.doWithSession))
                            .to(equal(1))
                    }
                    
                    context("when the auth service calls back with an error") {
                        let error = NSError(domain: "com.spotify.ios", code: 9876, userInfo: [NSLocalizedDescriptionKey: "error logging in"])
                        
                        it("calls back with the error") {
                            mockSpotifyAuthService.mocker.prepareForCallTo(MockSpotifyAuthService.Method.doWithSession, returnValue: SpotifyAuthService.AuthResult.Failure(error))
                            
                            spotifyUserService.retrieveCurrentUser(self.sptUserCallback)
                            
                            expect(self.callbackError).to(equal(error))
                            expect(self.callbackSpotifyUser).to(beNil())
                        }
                    }
                    
                    context("when the auth service calls back with canceled") {
                        it("calls back with the expected error") {
                            mockSpotifyAuthService.mocker.prepareForCallTo(MockSpotifyAuthService.Method.doWithSession, returnValue: SpotifyAuthService.AuthResult.Canceled)
                            
                            spotifyUserService.retrieveCurrentUser(self.sptUserCallback)
                            
                            expect(self.callbackError).to(equal(NSError(domain: Constants.Error.Domain, code: Constants.Error.SpotifyLoginCanceledCode,
                                userInfo: [NSLocalizedDescriptionKey: Constants.Error.SpotifyLoginCanceledMessage])))
                            expect(self.callbackSpotifyUser).to(beNil())
                        }
                    }
                }
            }
        }
    }
}