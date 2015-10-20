import TuneThatName

class MockSPTAuth: SPTAuth {
    
    let mocker = Mocker()
    
    struct Method {
        static let getSession = "getSession"
        static let setSession = "setSession"
        static let hasTokenRefreshService = "hasTokenRefreshService"
        static let renewSession = "renewSession"
    }
    
    override var session: SPTSession! {
        get {
            return mocker.mockCallTo(Method.getSession) as? SPTSession
        }
        set {
            mocker.recordCall(Method.setSession, parameters: newValue)
        }
    }
    
    override var hasTokenRefreshService: Bool {
        get {
            return mocker.mockCallTo(Method.hasTokenRefreshService) as! Bool
        }
    }
    
    override func renewSession(session: SPTSession!, callback: SPTAuthCallback!) {
        mocker.recordCall(Method.renewSession, parameters: session)
        callback(nil, mocker.returnValueForCallTo(Method.renewSession) as? SPTSession)
    }
}
