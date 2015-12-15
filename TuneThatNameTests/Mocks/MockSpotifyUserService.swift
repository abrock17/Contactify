@testable import TuneThatName

class MockSpotifyUserService: SpotifyUserService {
    
    let mocker = Mocker()
    
    struct Method {
        static let retrieveCurrentUser = "retrieveCurrentUser"
        static let getCachedCurrentUser = "getCachedCurrentUser"
    }
    
    override func retrieveCurrentUser(callback: SpotifyUserService.UserResult -> Void) {
        mocker.recordCall(Method.retrieveCurrentUser)
        if let result = mocker.returnValueForCallTo(Method.retrieveCurrentUser) as? SpotifyUserService.UserResult {
            callback(result)
        }
    }
    
    override func getCachedCurrentUser() -> SpotifyUser? {
        mocker.recordCall(Method.getCachedCurrentUser)
        return mocker.returnValueForCallTo(Method.getCachedCurrentUser) as? SpotifyUser
    }
}