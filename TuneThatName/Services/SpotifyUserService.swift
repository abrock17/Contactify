import Foundation

public class SpotifyUserService {
    
    public enum UserResult {
        case Success(SpotifyUser)
        case Failure(NSError)
    }
    
    let spotifyAuthService: SpotifyAuthService
    let userDefaults: NSUserDefaults
    
    public init(spotifyAuthService: SpotifyAuthService = SpotifyAuthService(),
        userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()) {
        self.spotifyAuthService = spotifyAuthService
        self.userDefaults = userDefaults
    }
    
    public func retrieveCurrentUser(callback: UserResult -> Void) {
        if let cachedCurrentUser = getCachedCurrentUser() {
            callback(.Success(cachedCurrentUser))
        } else {
            spotifyAuthService.doWithSession() {
                authResult in
                
                switch (authResult) {
                case .Success(let session):
                    SPTUser.requestCurrentUserWithAccessToken(session.accessToken) {
                        (error, result) in
                        
                        if error != nil {
                            callback(.Failure(error))
                        } else if let user = result as? SPTUser {
                            let spotifyUser = SpotifyUser(username: user.canonicalUserName, territory: user.territory)
                            self.cacheCurrentUser(spotifyUser)
                            callback(.Success(spotifyUser))
                        }
                    }
                case .Failure(let error):
                    callback(.Failure(error))
                case .Canceled:
                    callback(.Failure(NSError(domain: Constants.Error.Domain, code: Constants.Error.SpotifyLoginCanceledCode, userInfo: [NSLocalizedDescriptionKey: Constants.Error.SpotifyLoginCanceledMessage])))
                }
            }
        }
    }
    
    func getCachedCurrentUser() -> SpotifyUser? {
        var currentUser: SpotifyUser?
        if let currentUserData = userDefaults.dataForKey(Constants.StorageKeys.spotifyCurrentUser) {
            currentUser = NSKeyedUnarchiver.unarchiveObjectWithData(currentUserData) as? SpotifyUser
        }
        return currentUser
    }
    
    func cacheCurrentUser(spotifyUser: SpotifyUser) {
        let currentUserData = NSKeyedArchiver.archivedDataWithRootObject(spotifyUser)
        self.userDefaults.setObject(currentUserData, forKey: Constants.StorageKeys.spotifyCurrentUser)
    }
}