import Quick
import Nimble
@testable import TuneThatName

class SpotifyActionSheetControllerSpec: QuickSpec {
    
    override func spec() {
        var spotifyActionSheetController: SpotifyActionSheetController!
        var presentingView: UIView!
        var mockApplication: MockUIApplication!
        var mockSpotifyAuthService: MockSpotifyAuthService!
        var mockSpotifyUserService: MockSpotifyUserService!
        
        let spotifyUser = SpotifyUser(username: "fflinstone", territory: "BR")
        
        describe("SpotifyActionSheetController") {
            beforeEach() {
                presentingView = UIView(frame: CGRect(x: 1, y: 1, width: 1, height: 1))
                mockApplication = MockUIApplication()
                mockSpotifyAuthService = MockSpotifyAuthService()
                mockSpotifyUserService = MockSpotifyUserService()
            }
            
            describe("message") {
                beforeEach() {
                    mockSpotifyAuthService.mocker.prepareForCallTo(MockSpotifyAuthService.Method.getHasSession, returnValue: true)
                }
                
                context("when the current user is cached") {
                    it("displays the username in the message") {
                        mockSpotifyUserService.mocker.prepareForCallTo(MockSpotifyUserService.Method.getCachedCurrentUser, returnValue: spotifyUser)
                        spotifyActionSheetController = SpotifyActionSheetController(
                            presentingView: presentingView, application: mockApplication, spotifyAuthService:
                            mockSpotifyAuthService, spotifyUserService: mockSpotifyUserService)
                        
                        expect(spotifyActionSheetController.message).to(equal("Logged in as \"\(spotifyUser.username)\""))
                    }
                }
                
                context("when the current user is not cached") {
                    it("displays no message") {
                        mockSpotifyUserService.mocker.prepareForCallTo(MockSpotifyUserService.Method.getCachedCurrentUser, returnValue: nil)
                        spotifyActionSheetController = SpotifyActionSheetController(
                            presentingView: presentingView, application: mockApplication, spotifyAuthService:
                            mockSpotifyAuthService, spotifyUserService: mockSpotifyUserService)
                        
                        expect(spotifyActionSheetController.message).to(beNil())
                    }
                }
            }
            
            describe("actions") {
                context("when has session") {
                    it("has the expected actions") {
                        mockSpotifyAuthService.mocker.prepareForCallTo(MockSpotifyAuthService.Method.getHasSession, returnValue: true)
                        spotifyActionSheetController = SpotifyActionSheetController(
                            presentingView: presentingView, application: mockApplication, spotifyAuthService:
                            mockSpotifyAuthService, spotifyUserService: mockSpotifyUserService)

                        expect(spotifyActionSheetController.actions.count).to(equal(3))
                        expect(spotifyActionSheetController.actions[0].title).to(equal("Log in as a different user"))
                        expect(spotifyActionSheetController.actions[1].title).to(equal("spotify.com"))
                        expect(spotifyActionSheetController.actions[2].title).to(equal("Cancel"))
                    }
                }
                
                context("when does not have session") {
                    it("has the expected actions") {
                        mockSpotifyAuthService.mocker.prepareForCallTo(MockSpotifyAuthService.Method.getHasSession, returnValue: false)
                        spotifyActionSheetController = SpotifyActionSheetController(
                            presentingView: presentingView, application: mockApplication, spotifyAuthService:
                            mockSpotifyAuthService, spotifyUserService: mockSpotifyUserService)

                        expect(spotifyActionSheetController.actions.count).to(equal(3))
                            expect(spotifyActionSheetController.actions[0].title).to(equal("Log in to Spotify"))
                        expect(spotifyActionSheetController.actions[1].title).to(equal("spotify.com"))
                        expect(spotifyActionSheetController.actions[2].title).to(equal("Cancel"))
                    }
                }
            }
            
            describe("popoverPresentationController") {
                beforeEach() {
                    spotifyActionSheetController = SpotifyActionSheetController(
                        presentingView: presentingView, application: mockApplication, spotifyAuthService:
                        mockSpotifyAuthService, spotifyUserService: mockSpotifyUserService)
                }
                
                it("has the presenting view as its source view") {
                    if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
                        expect(spotifyActionSheetController.popoverPresentationController?.sourceView)
                            .to(beIdenticalTo(presentingView))
                    }
                }
                
                it("has the presenting view's bounds for its source rect") {
                    if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
                        expect(spotifyActionSheetController.popoverPresentationController?.sourceRect)
                            .to(equal(presentingView.bounds))
                    }
                }
            }
            
            describe("go to spotify") {
                it("opens the spotify URL") {
                    spotifyActionSheetController = SpotifyActionSheetController(
                        presentingView: presentingView, application: mockApplication, spotifyAuthService:
                        mockSpotifyAuthService, spotifyUserService: mockSpotifyUserService)

                    spotifyActionSheetController.goToSpotify(spotifyActionSheetController.actions[0])
                    
                    expect(mockApplication.mocker.getNthCallTo(MockUIApplication.Method.openURL, n: 0)?
                        .first as? NSURL).to(equal(NSURL(string: "https://www.spotify.com")!))
                }
            }
            
            describe("login") {
                beforeEach() {
                    spotifyActionSheetController = SpotifyActionSheetController(
                        presentingView: presentingView, application: mockApplication, spotifyAuthService:
                        mockSpotifyAuthService, spotifyUserService: mockSpotifyUserService)
                    
                    spotifyActionSheetController.login(spotifyActionSheetController.actions[0])
                }
                
                it("retrieves the current user from the user service") {
                    expect(mockSpotifyUserService.mocker.getCallCountFor(MockSpotifyUserService.Method.retrieveCurrentUser)).to(equal(1))
                }
            }
            
            describe("re-login") {
                beforeEach() {
                    spotifyActionSheetController = SpotifyActionSheetController(
                        presentingView: presentingView, application: mockApplication, spotifyAuthService:
                        mockSpotifyAuthService, spotifyUserService: mockSpotifyUserService)
                    
                    spotifyActionSheetController.reLogin(spotifyActionSheetController.actions[0])
                }
                
                it("calls logout on the auth service") {
                    expect(mockSpotifyAuthService.mocker.getCallCountFor(MockSpotifyAuthService.Method.logout)).to(equal(1))
                }
                
                it("retrieves the current user from the user service") {
                    expect(mockSpotifyUserService.mocker.getCallCountFor(MockSpotifyUserService.Method.retrieveCurrentUser)).to(equal(1))
                }
            }
        }
    }
}

class MockUIApplication: UIApplicationProtocol {
    
    struct Method {
        static let openURL = "openURL"
    }
    
    let mocker = Mocker()
    
    func openURL(url: NSURL) -> Bool {
        mocker.recordCall(Method.openURL, parameters: url)
        return true
    }
}