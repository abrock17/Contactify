import TuneThatName

class MockSpotifyUserService: SpotifyUserService {
    
    let mocker = Mocker()
    
    struct Method {
        static let retrieveCurrentUser = "retrieveCurrentUser"
    }
    
    override func retrieveCurrentUser(callback: SpotifyUserService.UserResult -> Void) {
        mocker.recordCall(Method.retrieveCurrentUser)
        if let result = mocker.returnValueForCallTo(Method.retrieveCurrentUser) as? SpotifyUserService.UserResult {
            callback(result)
        }
    }
}