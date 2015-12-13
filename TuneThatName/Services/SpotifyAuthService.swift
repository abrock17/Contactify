import Foundation

public class SpotifyAuthService: SPTAuthViewDelegate {
    
    public static let clientID = "02b72a9ba42742acbebb0d3277c9996f"

    static let sharedDefaultSPTAuth: SPTAuth = {
        let auth = SPTAuth.defaultInstance()
        auth.clientID = clientID
        auth.requestedScopes = [SPTAuthPlaylistModifyPublicScope, SPTAuthPlaylistModifyPrivateScope, SPTAuthStreamingScope, SPTAuthUserReadPrivateScope]
        auth.redirectURL = NSURL(string: "name-playlist-creator-login://return")
        auth.tokenSwapURL = NSURL(string: "https://name-playlist-spt-token-swap.herokuapp.com/swap")
        auth.tokenRefreshURL = NSURL(string: "https://name-playlist-spt-token-swap.herokuapp.com/refresh")
        auth.sessionUserDefaultsKey = "SpotifySessionData"
        return auth
    }()
    
    public enum AuthResult {
        case Success(SPTSession)
        case Failure(NSError)
        case Canceled
    }
    
    let spotifyAuth: SPTAuth
    let userDefaults: NSUserDefaults
    var getSpotifyAudioFacade: (() -> SpotifyAudioFacade) = { return SpotifyAudioFacadeImpl.sharedInstance }
    
    public var hasSession: Bool {
        get {
            return spotifyAuth.session != nil
        }
    }
    
    var postLoginCallback: (AuthResult -> Void)?
    
    public init(spotifyAuth: SPTAuth = sharedDefaultSPTAuth,
        userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()) {
        self.userDefaults = userDefaults
        self.spotifyAuth = spotifyAuth
    }
    
    public func doWithSession(callback: AuthResult -> Void) {
        if sessionIsValid() {
            callback(.Success(spotifyAuth.session))
        } else {
            refreshSession(callback)
        }
    }
    
    public func logout() {
        spotifyAuth.session = nil
        userDefaults.setObject(nil, forKey: Constants.StorageKeys.spotifyCurrentUser)
        getSpotifyAudioFacade().reset() {
            error in
            if error != nil {
                print("Error resetting spotify audio facade: \(error)")
            }
        }
    }
    
    func sessionIsValid() -> Bool {
        return spotifyAuth.session != nil && spotifyAuth.session.isValid()
    }
    
    func refreshSession(callback: AuthResult -> Void) {
        if spotifyAuth.hasTokenRefreshService {
            self.spotifyAuth.renewSession(self.spotifyAuth.session) {
                error, session in
                
                if error != nil {
                    print("Error renewing session: \(error)")
                }
                if session != nil {
                    self.spotifyAuth.session = session
                    callback(.Success(session!))
                } else {
                    self.openLogin(callback)
                }
            }
        } else {
            self.openLogin(callback)
        }
    }
    
    func openLogin(callback: (AuthResult -> Void)?) {
        self.postLoginCallback = callback
        
        let spotifyAuthController = SPTAuthViewController.authenticationViewControllerWithAuth(spotifyAuth)
        spotifyAuthController.delegate = self
        spotifyAuthController.modalPresentationStyle = UIModalPresentationStyle.CurrentContext
        spotifyAuthController.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        spotifyAuthController.clearCookies(nil)

        let topViewController = getTopViewControllerFrom(UIApplication.sharedApplication().delegate!.window!!.rootViewController!)
        
        topViewController.modalPresentationStyle = UIModalPresentationStyle.CurrentContext
        topViewController.definesPresentationContext = true
        
        topViewController.presentViewController(spotifyAuthController, animated: false, completion: nil)
    }
    
    func getTopViewControllerFrom(viewController: UIViewController) -> UIViewController {
        let topViewController: UIViewController
        if let navigationController = viewController as? UINavigationController {
            topViewController = navigationController
        } else if viewController.presentedViewController != nil {
            topViewController = getTopViewControllerFrom(viewController.presentedViewController!)
        } else {
            topViewController = viewController
        }
        
        return topViewController
    }
    
    @objc public func authenticationViewController(viewController: SPTAuthViewController, didFailToLogin error: NSError) {
        print("Login failed... error: \(error)")
        if let callback = self.postLoginCallback {
            callback(.Failure(error))
        }
    }
    
    @objc public func authenticationViewController(viewController: SPTAuthViewController, didLoginWithSession session: SPTSession) {
        print("Login succeeded... session: \(session)")
        if let callback = self.postLoginCallback {
            callback(.Success(session))
        }
    }
    
    @objc public func authenticationViewControllerDidCancelLogin(viewController: SPTAuthViewController) {
        if let callback = self.postLoginCallback {
            callback(.Canceled)
        }
    }
}