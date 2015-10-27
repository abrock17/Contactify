import Foundation

public class SpotifyUserService {
    
    public enum UserResult {
        case Success(SPTUser)
        case Failure(NSError)
    }
    
    let spotifyAuthService: SpotifyAuthService
    
    public init(spotifyAuthService: SpotifyAuthService = SpotifyAuthService()) {
        self.spotifyAuthService = spotifyAuthService
    }
    
    public func retrieveCurrentUser(callback: UserResult -> Void) {
        spotifyAuthService.doWithSession() {
            authResult in
            
            switch (authResult) {
            case .Success(let session):
                SPTUser.requestCurrentUserWithAccessToken(session.accessToken) {
                    (error, result) in
                    
                    if error != nil {
                        callback(.Failure(error))
                    } else if let user = result as? SPTUser {
                        callback(.Success(user))
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