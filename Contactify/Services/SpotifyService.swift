import Foundation

let spotifyTokenSwapURL = "https://name-playlist-spt-token-swap.herokuapp.com/swap"
let spotifyTokenRefreshURL = "https://name-playlist-spt-token-swap.herokuapp.com/refresh"

public class SpotifyService {
    
    let clientID = "02b72a9ba42742acbebb0d3277c9996f"
    let callbackURL = "name-playlist-creator-login://return"
    let sessionDataKey = "SpotifySessionData"
    let uiApplicationWrapper: UIApplicationWrapper!
    
    public init(uiApplicationWrapper: UIApplicationWrapper = UIApplicationWrapper()) {
        self.uiApplicationWrapper = uiApplicationWrapper
    }
    
    public func doWithSession(auth: SPTAuth = SPTAuth.defaultInstance(), sessionCallback: SPTAuthCallback!) {
        if let sessionData = NSUserDefaults.standardUserDefaults().objectForKey(sessionDataKey) as? NSData {
            if let storedSession = NSKeyedUnarchiver.unarchiveObjectWithData(sessionData) as? SPTSession {
                handleCallbackForStoredSession(storedSession, auth: auth, sessionCallback: sessionCallback)
            }
        } else {
            handleLoginAndCallback(auth: auth, sessionCallback: sessionCallback)
        }
    }
    
    func handleCallbackForStoredSession(storedSession: SPTSession!, auth: SPTAuth = SPTAuth.defaultInstance(), sessionCallback: SPTAuthCallback!) {
        
        if storedSession.isValid() {
            sessionCallback(nil, storedSession)
        } else {
            auth.renewSession(storedSession, withServiceEndpointAtURL: NSURL(string: spotifyTokenRefreshURL), callback: {(error: NSError?, session: SPTSession?) in
                
                if let renewedSession = session {
                    let renewedSessionData = NSKeyedArchiver.archivedDataWithRootObject(renewedSession)
                    NSUserDefaults.standardUserDefaults().setObject(renewedSessionData, forKey: self.sessionDataKey)
                }
                sessionCallback(error, session)
            })
        }
    }
    
    func handleLoginAndCallback(auth: SPTAuth = SPTAuth.defaultInstance(), sessionCallback: SPTAuthCallback!) {
        let loginURL = auth.loginURLForClientId(clientID, declaredRedirectURL: NSURL(string: callbackURL), scopes: [SPTAuthPlaylistModifyPublicScope, SPTAuthPlaylistModifyPrivateScope, SPTAuthStreamingScope])
        
        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC))),
            dispatch_get_main_queue()) {
                self.uiApplicationWrapper.openURL(loginURL)
                return
        }
        
        // wait for login to complete, fail, or timeout -- then handle callback
    }
}

public class UIApplicationWrapper {
    
    public init() {
    }
    
    public func openURL(url: NSURL) -> Bool {
        return UIApplication.sharedApplication().openURL(url)
    }
}