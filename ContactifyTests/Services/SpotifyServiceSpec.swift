import Contactify
import Foundation
import Quick
import Nimble

class SpotifyServiceSpec: QuickSpec {
    let sessionDataKey = "SpotifySessionData"
    
    override func spec() {
        
        describe("The SpotifyService") {
            var spotifyService: SpotifyService!
            var mockUIApplicationWrapper: MockUIApplicationWrapper!
            
            
            beforeEach() {
                mockUIApplicationWrapper = MockUIApplicationWrapper()
                spotifyService = SpotifyService(uiApplicationWrapper: mockUIApplicationWrapper)
            }
            
            afterEach() {
                NSUserDefaults.standardUserDefaults().removeObjectForKey(self.sessionDataKey)
            }
            
            describe("get session") {
                it("retrieves the session from user defaults") {
                    let expectedSession = SPTSession(userName: "user", accessToken: "token", expirationDate: NSDate())
                    let sessionData = NSKeyedArchiver.archivedDataWithRootObject(expectedSession)
                    NSUserDefaults.standardUserDefaults().setObject(sessionData, forKey: self.sessionDataKey)
                    
                    let actualSession = spotifyService.getSession()
                    expect(actualSession).toNot(beNil())
                    expect(actualSession?.accessToken).to(equal(expectedSession.accessToken))
                }
                
                context("when the session is not in user defaults") {
                    it("opens the login URL") {
                        let actualSession = spotifyService.getSession()
                        expect(mockUIApplicationWrapper.capturedUrl).toEventuallyNot(beNil())
                    }
                }
            }
        }
        
    }
}

class MockUIApplicationWrapper: UIApplicationWrapper {
    
    var capturedUrl: NSURL?
    
    override func openURL(url: NSURL) -> Bool {
        self.capturedUrl = url
        return true
    }
}