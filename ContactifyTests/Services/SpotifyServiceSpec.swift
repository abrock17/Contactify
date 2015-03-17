import Contactify
import Foundation
import Quick
import Nimble

let fakeRenewedToken = "renewed token"

class SpotifyServiceSpec: QuickSpec {
    let sessionDataKey = "SpotifySessionData"
    
    var callbackError: NSError?
    var callbackSession: SPTSession?
    
    func doWithSessionCallback(error: NSError?, session: SPTSession?) {
        self.callbackError = error
        self.callbackSession = session
    }

    override func spec() {
        
        describe("The SpotifyService") {
            var spotifyService: SpotifyService!
            var fakeUIApplicationWrapper: FakeUIApplicationWrapper!
            let fakeAuth = FakeSPTAuth()
            
            beforeEach() {
                fakeUIApplicationWrapper = FakeUIApplicationWrapper()
                spotifyService = SpotifyService(uiApplicationWrapper: fakeUIApplicationWrapper)
            }
            
            afterEach() {
                NSUserDefaults.standardUserDefaults().removeObjectForKey(self.sessionDataKey)
            }
            
            describe("user defaults") {
                xit("can test them") {
                    let spotifySession = SPTSession(userName: "user", accessToken: "token", expirationTimeInterval: 30)
                    let sessionData = NSKeyedArchiver.archivedDataWithRootObject(spotifySession)
                    NSUserDefaults.standardUserDefaults().setObject(sessionData, forKey: self.sessionDataKey)
                    
                    let userDefaults = NSUserDefaults.standardUserDefaults()
                    expect(userDefaults.dictionaryRepresentation().keys).toEventually(contain(self.sessionDataKey))
                    expect(userDefaults.objectForKey(self.sessionDataKey)).toEventuallyNot(beNil())
                    let storedSessionData = userDefaults.objectForKey(self.sessionDataKey) as NSData
                    expect((NSKeyedUnarchiver.unarchiveObjectWithData(storedSessionData) as? SPTSession)?.accessToken).toEventually(equal(fakeRenewedToken))
                }
            }
            
            describe("do with session") {
                context("when the session is in user defaults") {
                    
                    it("retrieves the session from user defaults") {
                        let storedSession = SPTSession(userName: "user", accessToken: "token", expirationTimeInterval: 30)
                        self.storeInUserDefaults(storedSession)
                        
                        spotifyService.doWithSession(self.doWithSessionCallback)
                        
                        expect(self.callbackSession).toNot(beNil())
                        expect(self.callbackSession?.accessToken).to(equal(storedSession.accessToken))
                    }
                }
                
                context("when the session in user defaults is invalid") {
                    beforeEach() {
                        let storedSession = SPTSession(userName: "user", accessToken: "token", expirationTimeInterval: -1)
                        self.storeInUserDefaults(storedSession)
                        spotifyService.doWithSession(self.doWithSessionCallback, auth: fakeAuth)
                    }
                    
                    xit("stores the renewed session in user defaults") {
                        let userDefaults = NSUserDefaults.standardUserDefaults()
                        expect(userDefaults.dictionaryRepresentation().keys).toEventually(contain(self.sessionDataKey))
                        expect(userDefaults.objectForKey(self.sessionDataKey)).toEventuallyNot(beNil())
                        let sessionData = userDefaults.objectForKey(self.sessionDataKey) as NSData
                        expect((NSKeyedUnarchiver.unarchiveObjectWithData(sessionData) as? SPTSession)?.accessToken).toEventually(equal(fakeRenewedToken))
                    }

                    it("renews the invalid session") {
                        expect(fakeAuth.requestedRenewalURL?.absoluteString).toEventually(contain("refresh"))
                        expect(self.callbackSession?.accessToken).toEventually(equal(fakeRenewedToken))
                    }
                    
                }
                
                context("when the session is not in user defaults") {
                    beforeEach() {
                        spotifyService.doWithSession(self.doWithSessionCallback)
                    }
                    
                    it("opens the login URL") {
                        expect(fakeUIApplicationWrapper.requestedURL?.absoluteString)
                            .toEventually(contain("accounts.spotify.com/authorize"))
                    }
                }
            }
            
            describe("handle login callback") {
                context("when the URL cannot be handled") {
                    beforeEach() {
                        fakeAuth.canHandleURL = false
                    }
                    
                    it("does not handle the URL") {
                        expect(spotifyService.handleLoginCallback(NSURL(string: "not-a-spotify-url://yep"), auth: fakeAuth)).toNot(beTrue())
                        expect(fakeAuth.handledAuthCallbackWithTriggeredAuthURL).toNot(beTrue())
                    }
                }
                
                context("when the URL can be handled without error") {
                    beforeEach() {
                        fakeAuth.canHandleURL = true
                        fakeAuth.authCallbackSession = SPTSession(userName: "user", accessToken: "token", expirationTimeInterval: 30)
                    }
                    
                    it("does handle the URL") {
                        expect(spotifyService.handleLoginCallback(NSURL(string: "login-callback://return"), auth: fakeAuth)).to(beTrue())
                        expect(fakeAuth.handledAuthCallbackWithTriggeredAuthURL).to(beTrue())
                    }
                    
                    xit("stores the new session in user defaults") {
                        spotifyService.handleLoginCallback(NSURL(string: "login-callback://return"), auth: fakeAuth)
                        expect(self.retrieveSessionFromUserDefaults()).toEventuallyNot(beNil())
                        expect(self.retrieveSessionFromUserDefaults()?.accessToken).toEventually(equal(fakeAuth.authCallbackSession?.accessToken))
                    }
                }
            }
        }
    }
    
    func storeInUserDefaults(spotifySession: SPTSession!) {
        let sessionData = NSKeyedArchiver.archivedDataWithRootObject(spotifySession)
        NSUserDefaults.standardUserDefaults().setObject(sessionData, forKey: self.sessionDataKey)
    }
    
    func retrieveSessionFromUserDefaults() -> SPTSession? {
        var session: SPTSession?
        
        if let sessionData = NSUserDefaults.standardUserDefaults().objectForKey(sessionDataKey) as? NSData {
            if let storedSession = NSKeyedUnarchiver.unarchiveObjectWithData(sessionData) as? SPTSession {
                return storedSession
            }
        }
        
        return session
    }
}

class FakeUIApplicationWrapper: UIApplicationWrapper {
    
    var requestedURL: NSURL?
    
    override func openURL(url: NSURL) -> Bool {
        self.requestedURL = url
        return true
    }
}

class FakeSPTAuth: SPTAuth {

    var requestedRenewalURL: NSURL?
    var canHandleURL = true
    var handledAuthCallbackWithTriggeredAuthURL = false
    var authCallbackError: NSError?
    var authCallbackSession: SPTSession?
    
    override func renewSession(session: SPTSession?, withServiceEndpointAtURL: NSURL?, callback: SPTAuthCallback?) {
        self.requestedRenewalURL = withServiceEndpointAtURL
        let renewedSession = SPTSession(userName: session?.canonicalUsername, accessToken: fakeRenewedToken, expirationTimeInterval: 30)
        callback?(nil, renewedSession)
    }
    
    override func canHandleURL(callbackURL: NSURL!, withDeclaredRedirectURL: NSURL!) -> Bool {
        return canHandleURL
    }
    
    override func handleAuthCallbackWithTriggeredAuthURL(url: NSURL!, tokenSwapServiceEndpointAtURL: NSURL!, callback: SPTAuthCallback!) {
        handledAuthCallbackWithTriggeredAuthURL = true
        callback(authCallbackError, authCallbackSession)
    }
}