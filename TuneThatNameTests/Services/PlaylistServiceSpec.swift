import TuneThatName
import Quick
import Nimble

class PlaylistServiceSpec: QuickSpec {
    
    var callbackPlaylist: Playlist?
    var callbackError: NSError?
    
    func playlistCallback(playlistResult: PlaylistService.PlaylistResult) {
        switch (playlistResult) {
        case .Success(let playlist):
            callbackPlaylist = playlist
        case .Failure(let error):
            callbackError = error
        }
    }
    
    override func spec() {
        describe("The Playlist Service") {
            var playlistService:PlaylistService!
            var mockContactService: MockContactService!
            var mockEchoNestService: MockEchoNestService!
            
            beforeEach() {
                self.callbackPlaylist = nil
                self.callbackError = nil
                
                mockContactService = MockContactService()
                mockEchoNestService = MockEchoNestService()
                playlistService = PlaylistService(echoNestService: mockEchoNestService, contactService: mockContactService)
            }
            
            describe("create a playlist") {
                it("retrieves all contacts from the contact service") {
                    playlistService.createPlaylist(numberOfSongs: 1, callback: self.playlistCallback)

                    expect(mockContactService.mocker.getNthCallTo(MockContactService.Method.retrieveAllContacts, n: 0)).toNot(beNil())
                }
                
                context("when the contact service calls back with an error") {
                    let contactServiceError = NSError(domain: "DOMAIN", code: 123, userInfo: [NSLocalizedDescriptionKey: "couldn't get no contacts"])

                    it("calls back with the same error") {
                        mockContactService.mocker.prepareForCallTo(MockContactService.Method.retrieveAllContacts, returnValue: ContactService.ContactListResult.Failure(contactServiceError))
                        
                        playlistService.createPlaylist(numberOfSongs: 1, callback: self.playlistCallback)
                        
                        expect(self.callbackError).toEventually(equal(contactServiceError))
                        expect(self.callbackPlaylist).to(beNil())
                    }
                }
                
                context("when the contact service calls back with a list of contacts with first names") {
                    let contactList = [
                        Contact(id: 1, firstName: "Johnny", lastName: "Hodges"),
                        Contact(id: 2, firstName: "Billy", lastName: "Crystal"),
                        Contact(id: 3, firstName: "Frankie", lastName: "Valli")]
                    
                    beforeEach() {
                        mockContactService.mocker.prepareForCallTo(MockContactService.Method.retrieveAllContacts, returnValue: ContactService.ContactListResult.Success(contactList))
                    }
                    
                    context("and the desired number of songs is the same as the number of contacts") {
                        it("finds songs for each name from the echo nest service") {
                            let numberOfSongs = contactList.count

                            playlistService.createPlaylist(numberOfSongs: contactList.count, callback: self.playlistCallback)
                            
                            expect(mockEchoNestService.mocker.recordedParameters[
                                MockEchoNestService.Method.findSong]?.count).toEventually(equal(numberOfSongs))
                            var nameMatchCount = 0
                            for contact in contactList {
                                let callsForName = self.getNumberOfTimesName(contact.firstName!, wasPassedToTheEchoNestService: mockEchoNestService)
                                expect(callsForName).to(equal(1))
                                nameMatchCount += callsForName
                            }
                            expect(nameMatchCount).to(equal(numberOfSongs))
                        }
                    }
                    
                    context("and the desired number of songs is less than the number of contacts") {
                        it("finds the right number of songs for a subset of unique contacts") {
                            let numberOfSongs = contactList.count - 1
                            
                            playlistService.createPlaylist(numberOfSongs: numberOfSongs, callback: self.playlistCallback)
                            
                            expect(mockEchoNestService.mocker.recordedParameters[
                                MockEchoNestService.Method.findSong]?.count).toEventually(equal(numberOfSongs))
                            var nameMatchCount = 0
                            for contact in contactList {
                                let callsForName = self.getNumberOfTimesName(contact.firstName!, wasPassedToTheEchoNestService: mockEchoNestService)
                                expect(callsForName).to(beLessThanOrEqualTo(1))
                                nameMatchCount += callsForName
                            }
                            expect(nameMatchCount).to(equal(numberOfSongs))
                        }
                    }
                    
                    context("and the desired number of songs is more than the number of contacts") {
                        it("finds the right number of songs for all contacts reusing only as many as necessary") {
                            let numberOfSongs = contactList.count + 1
                            
                            playlistService.createPlaylist(numberOfSongs: numberOfSongs, callback: self.playlistCallback)
                            
                            expect(mockEchoNestService.mocker.recordedParameters[
                                MockEchoNestService.Method.findSong]?.count).toEventually(equal(numberOfSongs))
                            var nameMatchCount = 0
                            for contact in contactList {
                                let callsForName = self.getNumberOfTimesName(contact.firstName!, wasPassedToTheEchoNestService: mockEchoNestService)
                                expect(callsForName).to(beGreaterThanOrEqualTo(1))
                                nameMatchCount += callsForName
                            }
                            expect(nameMatchCount).to(equal(numberOfSongs))
                        }
                    }
                }
                
                context("when the contact service calls back with contacts not all of whom have first names") {
                    let contactList = [
                        Contact(id: 1, firstName: "Sylvester", lastName: "Stalone"),
                        Contact(id: 2, firstName: nil, lastName: "Schwarzenegger"),
                        Contact(id: 3, firstName: "", lastName: "Van Damme")]

                    beforeEach() {
                        mockContactService.mocker.prepareForCallTo(MockContactService.Method.retrieveAllContacts, returnValue: ContactService.ContactListResult.Success(contactList))
                    }
                    
                    it("finds the right number songs using only contacts that have first names") {
                        let numberOfSongs = contactList.count
                        
                        playlistService.createPlaylist(numberOfSongs: numberOfSongs, callback: self.playlistCallback)
                        
                        expect(mockEchoNestService.mocker.recordedParameters[
                            MockEchoNestService.Method.findSong]?.count).toEventually(equal(numberOfSongs))
                        expect(self.getNumberOfTimesName(contactList[0].firstName!, wasPassedToTheEchoNestService: mockEchoNestService)).to(equal(numberOfSongs))
                    }
                }
                
                context("when the contact service calls back with an empty list") {
                    let expectedError = NSError(domain: Constants.Error.Domain, code: Constants.Error.NoContactsCode, userInfo: [NSLocalizedDescriptionKey: Constants.Error.NoContactsMessage])
                    it("calls back with an appropriate error") {
                        mockContactService.mocker.prepareForCallTo(MockContactService.Method.retrieveAllContacts, returnValue: ContactService.ContactListResult.Success([]))
                        
                        playlistService.createPlaylist(numberOfSongs: 1, callback: self.playlistCallback)
                        
                        expect(self.callbackError).toEventually(equal(expectedError))
                        expect(self.callbackPlaylist).to(beNil())
                    }
                }
            }
        }
    }
    
    func getNumberOfTimesName(name: String, wasPassedToTheEchoNestService service: MockEchoNestService) -> Int {
        var numberOfCalls = 0
        if let findSongParameters = service.mocker.recordedParameters[MockEchoNestService.Method.findSong] {
            
            for parameters in findSongParameters {
                if let titleSearchTerm = parameters[0] as? String where titleSearchTerm == name {
                    numberOfCalls++
                }
            }
        }
        
        return numberOfCalls
    }
}

class MockContactService: ContactService {
    
    struct Method {
        static let retrieveAllContacts = "retrieveAllContacts"
    }
    
    let mocker = Mocker()
    
    override func retrieveAllContacts(callback: ContactListResult -> Void) {
        mocker.recordCall(Method.retrieveAllContacts)
        let contactListResult: ContactListResult
        if let mockedContactListResult = mocker.returnValueForCallTo(Method.retrieveAllContacts) as? ContactListResult {
            contactListResult = mockedContactListResult
        } else {
            contactListResult = ContactService.ContactListResult.Success([])
        }
        callback(contactListResult)
    }
}