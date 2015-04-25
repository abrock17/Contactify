import TuneThatName
import Quick
import Nimble

class PlaylistServiceSpec: QuickSpec {
    
    override func spec() {
        describe("The Playlist Service") {
            var playlistService:PlaylistService!
            var mockContactService: ContactService!
            
            beforeEach() {
                playlistService = PlaylistService()
            }
            describe("create a playlist") {
                it("calls the contact service") {
                    
                }
                
            }
        }
    }
}

class MockContactService: ContactService {
    
    struct Method {
        static let retrieveAllContacts = "retrieveAllContacts"
    }
    
    let mocker = Mocker()
    
    override func retrieveAllContacts(callback: ContactListResult -> Void) {
        mocker.recordCall(Method.retrieveAllContacts)
        callback(mocker.returnValueForCallTo(Method.retrieveAllContacts) as! ContactListResult)
    }
}