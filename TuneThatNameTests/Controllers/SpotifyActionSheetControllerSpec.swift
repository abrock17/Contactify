import Quick
import Nimble
@testable import TuneThatName

class SpotifyActionSheetControllerSpec: QuickSpec {
    
    override func spec() {
        var spotifyActionSheetController: SpotifyActionSheetController!
        var mockApplication: MockUIApplication!
        var mockSpotifyAuthService: MockSpotifyAuthService!
        
        describe("SpotifyActionSheetController") {
            beforeEach() {
                mockApplication = MockUIApplication()
                mockSpotifyAuthService = MockSpotifyAuthService()
                spotifyActionSheetController = SpotifyActionSheetController(application: mockApplication,
                    spotifyAuthService: mockSpotifyAuthService)
            }
            
            describe("actions") {
                it("has the expected actions") {
                    expect(spotifyActionSheetController.actions.count).to(equal(3))
                    expect(spotifyActionSheetController.actions[0].title).to(equal("Go to Spotify"))
                    expect(spotifyActionSheetController.actions[1].title).to(equal("Log out of Spotify"))
                    expect(spotifyActionSheetController.actions[2].title).to(equal("Cancel"))
                }
            }
            
            describe("go to spotify") {
                it("opens the spotify URL") {
                    spotifyActionSheetController.goToSpotify(spotifyActionSheetController.actions[0])
                    expect(mockApplication.mocker.getNthCallTo(MockUIApplication.Method.openURL, n: 0)?
                        .first as? NSURL).to(equal(NSURL(string: "https://www.spotify.com")!))
                }
            }
            
            describe("logout") {
                it("calls logout on the auth service") {
                    spotifyActionSheetController.logout(spotifyActionSheetController.actions[1])
                    expect(mockSpotifyAuthService.mocker.getCallCountFor(MockSpotifyAuthService.Method.logout)).to(equal(1))
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