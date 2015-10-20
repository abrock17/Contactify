import Foundation

public class SpotifyAuthService: SPTAuthViewDelegate {
    
    public enum AuthResult {
        case Success(SPTSession)
        case Failure(NSError)
        case Canceled
    }
    
    let spotifyAuth: SPTAuth
    
    var postLoginCallback: (AuthResult -> Void)?
    
    public init(spotifyAuth: SPTAuth = SPTAuth.defaultInstance()) {
        self.spotifyAuth = spotifyAuth
    }
    
    public func doWithSession(callback: AuthResult -> Void) {
        if sessionIsValid() {
            callback(.Success(spotifyAuth.session))
        } else {
            refreshSession(callback)
        }
    }
    
    func sessionIsValid() -> Bool {
        return spotifyAuth.session != nil && spotifyAuth.session.isValid()
    }
    
    func refreshSession(callback: AuthResult -> Void) {
        if spotifyAuth.hasTokenRefreshService {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                self.spotifyAuth.renewSession(self.spotifyAuth.session) {
                    error, session in
                    
                    dispatch_async(dispatch_get_main_queue()) {
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