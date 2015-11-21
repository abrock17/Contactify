import TuneThatName

class MockSpotifyAuthService: SpotifyAuthService {
    
    let mocker = Mocker()
    
    struct Method {
        static let doWithSession = "doWithSession"
        static let getHasSession = "getHasSession"
        static let logout = "logout"
    }
    
    override var hasSession: Bool {
        get {
            if let mockedLoggedIn = mocker.mockCallTo(Method.getHasSession) as? Bool {
                return mockedLoggedIn
            } else {
                return true
            }
        }
    }
    
    override func doWithSession(callback: AuthResult -> Void) {
        mocker.recordCall(Method.doWithSession)
        if let result = mocker.returnValueForCallTo(Method.doWithSession) as? AuthResult {
            callback(result)
        }
    }
    
    override func logout() {
        mocker.recordCall(Method.logout)
    }
}