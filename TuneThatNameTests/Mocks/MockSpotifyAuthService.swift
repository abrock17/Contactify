import TuneThatName

class MockSpotifyAuthService: SpotifyAuthService {
    
    let mocker = Mocker()
    
    struct Method {
        static let doWithSession = "doWithSession"
        static let logout = "logout"
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