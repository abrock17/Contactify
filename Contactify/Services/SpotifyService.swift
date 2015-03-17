import Foundation

var loggingIn = false

public class SpotifyService {
    
    let clientID = "02b72a9ba42742acbebb0d3277c9996f"
    let callbackURL = "name-playlist-creator-login://return"
    let tokenSwapURLString = "https://name-playlist-spt-token-swap.herokuapp.com/swap"
    let tokenRefreshURLString = "https://name-playlist-spt-token-swap.herokuapp.com/refresh"
    let sessionDataKey = "SpotifySessionData"
    let uiApplicationWrapper: UIApplicationWrapper!
    
    public init(uiApplicationWrapper: UIApplicationWrapper = UIApplicationWrapper()) {
        self.uiApplicationWrapper = uiApplicationWrapper
    }
    
    class var sharedInstance: SpotifyService {
        struct Singleton {
            static let instance = SpotifyService()
        }

        return Singleton.instance
    }
    
    public func doWithSession(sessionCallback: SPTAuthCallback!, auth: SPTAuth = SPTAuth.defaultInstance()) {
        if let sessionData = NSUserDefaults.standardUserDefaults().objectForKey(sessionDataKey) as? NSData {
            if let storedSession = NSKeyedUnarchiver.unarchiveObjectWithData(sessionData) as? SPTSession {
                handleCallbackForStoredSession(storedSession, sessionCallback: sessionCallback, auth: auth)
            }
        } else {
            redirectToLogin(auth)
            
            // wait for login to complete, fail, or timeout -- then handle callback
        }
    }
    
    func handleCallbackForStoredSession(storedSession: SPTSession!, sessionCallback: SPTAuthCallback!, auth: SPTAuth) {
        
        if storedSession.isValid() {
            sessionCallback(nil, storedSession)
        } else {
            auth.renewSession(storedSession, withServiceEndpointAtURL: NSURL(string: tokenRefreshURLString), callback: {(error: NSError?, session: SPTSession?) in
                
                if let renewedSession = session {
                    let renewedSessionData = NSKeyedArchiver.archivedDataWithRootObject(renewedSession)
                    NSUserDefaults.standardUserDefaults().setObject(renewedSessionData, forKey: self.sessionDataKey)
                }
                sessionCallback(error, session)
            })
        }
    }
    
    func redirectToLogin(auth: SPTAuth) {
        let loginURL = auth.loginURLForClientId(clientID, declaredRedirectURL: NSURL(string: callbackURL), scopes: [SPTAuthPlaylistModifyPublicScope, SPTAuthPlaylistModifyPrivateScope, SPTAuthStreamingScope])
        
        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC))),
            dispatch_get_main_queue()) {
                self.uiApplicationWrapper.openURL(loginURL)
                return
        }
    }
    
    public func handleLoginCallback(callbackURL: NSURL!, auth: SPTAuth = SPTAuth.defaultInstance()) -> Bool {
        var handledAuthCallback = false
        let tokenSwapURL = NSURL(string: tokenSwapURLString)
        if auth.canHandleURL(callbackURL, withDeclaredRedirectURL: tokenSwapURL) {
            
            auth.handleAuthCallbackWithTriggeredAuthURL(callbackURL, tokenSwapServiceEndpointAtURL: tokenSwapURL,
                callback: {(error: NSError?, session: SPTSession?) in
                    if let authenticationError = error {
                        println("Authentication error: \(authenticationError)")
                    } else {
                        let sessionData = NSKeyedArchiver.archivedDataWithRootObject(session!)
                        NSUserDefaults.standardUserDefaults().setObject(sessionData, forKey: self.sessionDataKey)
                    }
            })
            handledAuthCallback = true
        }
        
        return handledAuthCallback
    }
}

public class UIApplicationWrapper {
    
    public init() {
    }
    
    public func openURL(url: NSURL) -> Bool {
        return UIApplication.sharedApplication().openURL(url)
    }
}