import TuneThatName
import Quick
import Nimble

class PlaylistServiceSpec: QuickSpec {
    
    var callbackPlaylistList = [Playlist]()
    var callbackErrorList = [NSError]()
    
    func playlistCallback(playlistResult: PlaylistService.PlaylistResult) {
        println("callback result : \(playlistResult)")
        switch (playlistResult) {
        case .Success(let playlist):
            callbackPlaylistList.append(playlist)
        case .Failure(let error):
            callbackErrorList.append(error)
        }
    }
    
    override func spec() {
        describe("The Playlist Service") {
            var playlistService:PlaylistService!
            var mockContactService: MockContactService!
            var mockEchoNestService: MockEchoNestService!
            
            beforeEach() {
                self.callbackPlaylistList.removeAll(keepCapacity: false)
                self.callbackErrorList.removeAll(keepCapacity: false)
                
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
                        
                        expect(self.callbackErrorList.count).toEventually(equal(1))
                        expect(self.callbackErrorList[0]).toEventually(equal(contactServiceError))
                        expect(self.callbackPlaylistList).to(beEmpty())
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
                        let numberOfSongs = contactList.count
                        
                        it("finds songs for each name from the echo nest service") {
                            playlistService.createPlaylist(numberOfSongs: contactList.count, callback: self.playlistCallback)
                            
                            expect(self.numberOfTimesFindSongWasCalled(mockEchoNestService)).toEventually(equal(numberOfSongs))
                            for contact in contactList {
                                expect(self.numberOfTimesFindSongWasCalledForName(contact.firstName!, mockEchoNestService: mockEchoNestService)).to(equal(1))
                            }
                        }
                    }
                    
                    context("and the desired number of songs is less than the number of contacts") {
                        let numberOfSongs = contactList.count - 1
                        
                        it("finds the right number of songs for a subset of unique contacts") {
                            playlistService.createPlaylist(numberOfSongs: numberOfSongs, callback: self.playlistCallback)
                            
                            expect(self.numberOfTimesFindSongWasCalled(mockEchoNestService)).toEventually(equal(numberOfSongs))
                            for contact in contactList {
                                expect(self.numberOfTimesFindSongWasCalledForName(contact.firstName!, mockEchoNestService: mockEchoNestService)).to(beLessThanOrEqualTo(1))
                            }
                        }
                    }
                    
                    context("and the desired number of songs is more than the number of contacts") {
                        let numberOfSongs = contactList.count + 1
                        
                        it("finds the right number of songs for all contacts reusing only as many as necessary") {
                            playlistService.createPlaylist(numberOfSongs: numberOfSongs, callback: self.playlistCallback)
                            
                            expect(self.numberOfTimesFindSongWasCalled(mockEchoNestService)).toEventually(equal(numberOfSongs))
                            for contact in contactList {
                                expect(self.numberOfTimesFindSongWasCalledForName(contact.firstName!, mockEchoNestService: mockEchoNestService)).to(beGreaterThanOrEqualTo(1))
                            }
                        }
                    }
                    
                    context("and the echo nest service calls back with a song for each contact name") {
                        let numberOfSongs = contactList.count
                        let expectedSongs = [
                            Song(title: "title 1", artistName: "artist 1", uri: NSURL(string: "uri1")),
                            Song(title: "title 2", artistName: "artist 2", uri: NSURL(string: "uri2")),
                            Song(title: "title 3", artistName: "artist 3", uri: NSURL(string: "uri3"))]
                        
                        it("calls back with a playlist containing the songs") {
                            for song in expectedSongs {
                                mockEchoNestService.mocker.prepareForCallTo(MockEchoNestService.Method.findSong, returnValue: MockEchoNestService.SongResult.Success(song))
                            }

                            playlistService.createPlaylist(numberOfSongs: numberOfSongs, callback: self.playlistCallback)
                            
                            expect(self.callbackPlaylistList.count).toEventually(equal(1))
                            expect(self.callbackPlaylistList[0].songs).toEventually(equal(expectedSongs))
                        }
                    }
                    
                    context("and the echo nest service calls back with an error for one of the names") {
                        let numberOfSongs = contactList.count - 1
                        let echoNestResults: [EchoNestService.SongResult] = [
                            .Success(Song(title: "title 1", artistName: "artist 1", uri: NSURL(string: "uri1"))),
                            .Failure(NSError(domain: "d0m41n", code: 42, userInfo: nil)),
                            .Success(Song(title: "title 2", artistName: "artist 2", uri: NSURL(string: "uri2")))]
                        
                        it("retries with a different name") {
                            for result in echoNestResults {
                                mockEchoNestService.mocker.prepareForCallTo(MockEchoNestService.Method.findSong, returnValue: result)
                            }

                            playlistService.createPlaylist(numberOfSongs: numberOfSongs, callback: self.playlistCallback)
                            
                            expect(self.numberOfTimesFindSongWasCalled(mockEchoNestService)).toEventually(equal(numberOfSongs + 1))
                            for contact in contactList {
                                expect(self.numberOfTimesFindSongWasCalledForName(contact.firstName!, mockEchoNestService: mockEchoNestService)).to(equal(1))
                            }
                        }
                    }
                    
                    context("and the echo nest service calls back with a nil song result for one of the names") {
                        let numberOfSongs = contactList.count - 1
                        let echoNestResults: [EchoNestService.SongResult] = [
                            .Success(Song(title: "title 1", artistName: "artist 1", uri: NSURL(string: "uri1"))),
                            .Success(nil),
                            .Success(Song(title: "title 2", artistName: "artist 2", uri: NSURL(string: "uri2")))]
                        
                        it("retries with a different name") {
                            for result in echoNestResults {
                                mockEchoNestService.mocker.prepareForCallTo(MockEchoNestService.Method.findSong, returnValue: result)
                            }
                            
                            playlistService.createPlaylist(numberOfSongs: numberOfSongs, callback: self.playlistCallback)
                            
                            expect(self.numberOfTimesFindSongWasCalled(mockEchoNestService)).toEventually(equal(numberOfSongs + 1))
                            for contact in contactList {
                                expect(self.numberOfTimesFindSongWasCalledForName(contact.firstName!, mockEchoNestService: mockEchoNestService)).to(equal(1))
                            }
                        }
                    }
                    
                    context("and the echo nest service calls back with three errors") {
                        let numberOfSongs = contactList.count
                        let lastError = NSError(domain: "89", code: 89, userInfo: nil)
                        let echoNestResults: [EchoNestService.SongResult] = [
                            .Failure(NSError(domain: "87", code: 87, userInfo: nil)),
                            .Failure(NSError(domain: "88", code: 88, userInfo: nil)),
                            .Failure(lastError)]
                        
                        it("calls back with the last error of the three") {
                            for result in echoNestResults {
                                mockEchoNestService.mocker.prepareForCallTo(MockEchoNestService.Method.findSong, returnValue: result)
                            }
                            
                            playlistService.createPlaylist(numberOfSongs: numberOfSongs, callback: self.playlistCallback)
                            
                            expect(self.numberOfTimesFindSongWasCalled(mockEchoNestService)).toEventually(equal(contactList.count))
                            expect(self.callbackErrorList.count).toEventually(equal(1))
                            expect(self.callbackErrorList[0]).toEventually(equal(lastError))
                            expect(self.callbackPlaylistList).to(beEmpty())
                        }
                    }
                }
                
                context("when the contact service calls back with a larger list of contacts with first names") {
                    let contactList = Array(1...20).map({Contact(id: Int32($0), firstName: "John", lastName: "Doe")})
                    beforeEach() {
                        mockContactService.mocker.prepareForCallTo(MockContactService.Method.retrieveAllContacts, returnValue: ContactService.ContactListResult.Success(contactList))
                    }
                    
                    context("and the echo nest service calls back with errors for at least 20% calls to find songs") {
                        let numberOfSongs = contactList.count
                        let lastError = NSError(domain: "89", code: 89, userInfo: nil)
                        let echoNestResults: [EchoNestService.SongResult] = [
                            .Success(Song(title: "title 1", artistName: "artist 1", uri: NSURL(string: "uri1"))),
                            .Failure(NSError(domain: "85", code: 87, userInfo: nil)),
                            .Failure(NSError(domain: "86", code: 88, userInfo: nil)),
                            .Failure(NSError(domain: "87", code: 87, userInfo: nil)),
                            .Failure(NSError(domain: "88", code: 88, userInfo: nil)),
                            .Failure(lastError)]
                        
                        it("calls back only with the first error over 20%") {
                            for result in echoNestResults {
                                mockEchoNestService.mocker.prepareForCallTo(MockEchoNestService.Method.findSong, returnValue: result)
                            }
                            
                            playlistService.createPlaylist(numberOfSongs: numberOfSongs, callback: self.playlistCallback)
                            
                            expect(self.numberOfTimesFindSongWasCalled(mockEchoNestService)).toEventually(equal(contactList.count))
                            expect(self.callbackErrorList.count).toEventually(equal(1))
                            expect(self.callbackErrorList[0]).toEventually(equal(lastError))
                            expect(self.callbackPlaylistList).to(beEmpty())
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
                        
                        expect(self.numberOfTimesFindSongWasCalled(mockEchoNestService)).toEventually(equal(numberOfSongs))
                        expect(self.numberOfTimesFindSongWasCalledForName(contactList[0].firstName!, mockEchoNestService: mockEchoNestService)).to(equal(numberOfSongs))
                    }
                }
                
                context("when the contact service calls back with an empty list") {
                    let expectedError = NSError(domain: Constants.Error.Domain, code: Constants.Error.NoContactsCode, userInfo: [NSLocalizedDescriptionKey: Constants.Error.NoContactsMessage])
                    it("calls back with an appropriate error") {
                        mockContactService.mocker.prepareForCallTo(MockContactService.Method.retrieveAllContacts, returnValue: ContactService.ContactListResult.Success([]))
                        
                        playlistService.createPlaylist(numberOfSongs: 1, callback: self.playlistCallback)
                        
                        expect(self.callbackErrorList.count).toEventually(equal(1))
                        expect(self.callbackErrorList[0]).toEventually(equal(expectedError))
                        expect(self.callbackPlaylistList).to(beEmpty())
                    }
                }
            }
        }
    }
    
    func numberOfTimesFindSongWasCalled(mockEchoNestService: MockEchoNestService) -> Int {
        return mockEchoNestService.mocker.recordedParameters[MockEchoNestService.Method.findSong]?.count ?? 0
    }
    
    func numberOfTimesFindSongWasCalledForName(name: String, mockEchoNestService: MockEchoNestService) -> Int {
        var numberOfCalls = 0
        if let findSongParameters = mockEchoNestService.mocker.recordedParameters[MockEchoNestService.Method.findSong] {
            
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