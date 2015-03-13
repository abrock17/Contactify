import Foundation

public class SpotifyService {
    
    let clientID = "02b72a9ba42742acbebb0d3277c9996f"
    let callbackURL = "name-playlist-creator-login://return"
    let sessionDataKey = "SpotifySessionData"
    let uiApplicationWrapper: UIApplicationWrapper!
    
    public init(uiApplicationWrapper: UIApplicationWrapper = UIApplicationWrapper()) {
        self.uiApplicationWrapper = uiApplicationWrapper
    }
    
    public func getSession() -> SPTSession? {
        var session: SPTSession?
        if let sessionData = NSUserDefaults.standardUserDefaults().objectForKey(sessionDataKey) as? NSData {
            session = NSKeyedUnarchiver.unarchiveObjectWithData(sessionData) as? SPTSession
        } else {
            let auth = SPTAuth.defaultInstance()
            let loginURL = auth.loginURLForClientId(clientID, declaredRedirectURL: NSURL(string: callbackURL), scopes: [SPTAuthPlaylistModifyPublicScope, SPTAuthPlaylistModifyPrivateScope, SPTAuthStreamingScope])
            dispatch_after(
                dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC))),
                dispatch_get_main_queue()) {
                    self.uiApplicationWrapper.openURL(loginURL)
                    return
            }
        }
        return session
    }
}

public class UIApplicationWrapper {
    
    public init() {
    }
    
    public func openURL(url: NSURL) -> Bool {
        return UIApplication.sharedApplication().openURL(url)
    }
}