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
            let arbitrarySongPreferences = SongPreferences(favorPopular: false)
            
            beforeEach() {
                self.callbackPlaylistList.removeAll(keepCapacity: false)
                self.callbackErrorList.removeAll(keepCapacity: false)
                
                mockContactService = MockContactService()
                mockEchoNestService = MockEchoNestService()
                playlistService = PlaylistService(echoNestService: mockEchoNestService, contactService: mockContactService)
            }
            
            describe("create a playlist") {
                it("retrieves all contacts from the contact service") {
                    playlistService.createPlaylist(numberOfSongs: 1, songPreferences: arbitrarySongPreferences, callback: self.playlistCallback)

                    expect(mockContactService.mocker.getNthCallTo(MockContactService.Method.retrieveAllContacts, n: 0)).toNot(beNil())
                }
                
                context("when the contact service calls back with an error") {
                    let contactServiceError = NSError(domain: "DOMAIN", code: 123, userInfo: [NSLocalizedDescriptionKey: "couldn't get no contacts"])

                    it("calls back with the same error") {
                        mockContactService.mocker.prepareForCallTo(MockContactService.Method.retrieveAllContacts, returnValue: ContactService.ContactListResult.Failure(contactServiceError))
                        
                        playlistService.createPlaylist(numberOfSongs: 1, songPreferences: arbitrarySongPreferences, callback: self.playlistCallback)
                        
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
                        
                        it("calls the echo nest service once for each contact") {
                            playlistService.createPlaylist(numberOfSongs: contactList.count, songPreferences: arbitrarySongPreferences, callback: self.playlistCallback)
                            
                            expect(self.numberOfTimesFindSongsWasCalled(mockEchoNestService)).toEventually(equal(numberOfSongs))
                            for contact in contactList {
                                expect(self.numberOfTimesFindSongsWasCalledForName(contact.firstName!, mockEchoNestService: mockEchoNestService)).to(equal(1))
                            }
                        }
                    }
                    
                    context("and the desired number of songs is less than the number of contacts") {
                        let numberOfSongs = contactList.count - 1
                        
                        it("calls the echo nest service only for a subset of unique contacts") {
                            playlistService.createPlaylist(numberOfSongs: numberOfSongs, songPreferences: arbitrarySongPreferences, callback: self.playlistCallback)
                            
                            expect(self.numberOfTimesFindSongsWasCalled(mockEchoNestService)).toEventually(equal(numberOfSongs))
                            for contact in contactList {
                                expect(self.numberOfTimesFindSongsWasCalledForName(contact.firstName!, mockEchoNestService: mockEchoNestService)).to(beLessThanOrEqualTo(1))
                            }
                        }
                    }
                    
                    context("and the desired number of songs is more than the number of contacts") {
                        let numberOfSongs = contactList.count + 1
                        
                        it("calls the echo nest services once for each contact") {
                            playlistService.createPlaylist(numberOfSongs: numberOfSongs, songPreferences: arbitrarySongPreferences, callback: self.playlistCallback)
                            
                            expect(self.numberOfTimesFindSongsWasCalled(mockEchoNestService))
                                .toEventually(equal(contactList.count))
                            for contact in contactList {
                                expect(self.numberOfTimesFindSongsWasCalledForName(contact.firstName!, mockEchoNestService: mockEchoNestService)).to(equal(1))
                            }
                        }
                        
                        context("and the echo nest service calls back with multiple songs for each name") {
                            let echoNestSongLists = [
                                [Song(title: "Johnny's Song", artistName: "artist 1", uri: NSURL(string: "uri1")!),
                                    Song(title: "Johnny's Song 2", artistName: "artist 4", uri: NSURL(string: "uri4")!)],
                                [Song(title: "Billy's Song", artistName: "artist 2", uri: NSURL(string: "uri2")!),
                                    Song(title: "Billy's Song 2", artistName: "artist 5", uri: NSURL(string: "uri5")!)],
                                [Song(title: "Frankie's Song", artistName: "artist 3", uri: NSURL(string: "uri3")!),
                                    Song(title: "Frankie's Song 2", artistName: "artist 6", uri: NSURL(string: "uri6")!)]]
                            
                            beforeEach() {
                                for songList in echoNestSongLists {
                                    mockEchoNestService.mocker.prepareForCallTo(MockEchoNestService.Method.findSongs, returnValue: EchoNestService.SongsResult.Success(songList))
                                }
                            }
                            
                            it("calls back with a playlist of the correct size with at least one song from each search result list") {
                                playlistService.createPlaylist(numberOfSongs: numberOfSongs, songPreferences: arbitrarySongPreferences, callback: self.playlistCallback)
                                
                                expect(self.callbackPlaylistList.count).toEventually(equal(1))
                                let playlistSongs = self.callbackPlaylistList.first!.songs
                                expect(playlistSongs.count).toEventually(equal(numberOfSongs))
                                for echoNestSongList in echoNestSongLists {
                                    var songCount = 0
                                    for echoNestSong in echoNestSongList {
                                        for playlistSong in playlistSongs {
                                            if echoNestSong == playlistSong {
                                                songCount++
                                            }
                                        }
                                    }
                                    expect(songCount).to(beGreaterThanOrEqualTo(1))
                                }
                            }
                        }
                    }
                    
                    context("and the echo nest service calls back with a song for each contact name") {
                        let numberOfSongs = contactList.count
                        let expectedSongs = [
                            Song(title: "Johnny's Song", artistName: "artist 1", uri: NSURL(string: "uri1")!),
                            Song(title: "Billy's Song", artistName: "artist 2", uri: NSURL(string: "uri2")!),
                            Song(title: "Frankie's Song", artistName: "artist 3", uri: NSURL(string: "uri3")!)]
                        
                        it("calls back with a playlist containing the songs") {
                            for song in expectedSongs {
                                mockEchoNestService.mocker.prepareForCallTo(MockEchoNestService.Method.findSongs, returnValue: MockEchoNestService.SongsResult.Success([song]))
                            }

                            playlistService.createPlaylist(numberOfSongs: numberOfSongs, songPreferences: arbitrarySongPreferences, callback: self.playlistCallback)
                            
                            expect(self.callbackPlaylistList.count).toEventually(equal(1))
                            expect(self.callbackPlaylistList[0].songs.count).toEventually(equal(numberOfSongs))
                            for song in expectedSongs {
                                expect(self.callbackPlaylistList.first?.songs).toEventually(contain(song))
                            }
                        }
                    }
                    
                    context("and the echo nest service calls back with an error for one of the names") {
                        let numberOfSongs = contactList.count - 1
                        let echoNestResults: [EchoNestService.SongsResult] = [
                            .Success([Song(title: "title 1", artistName: "artist 1", uri: NSURL(string: "uri1")!)]),
                            .Failure(NSError(domain: "d0m41n", code: 42, userInfo: nil)),
                            .Success([Song(title: "title 2", artistName: "artist 2", uri: NSURL(string: "uri2")!)])]
                        
                        it("retries with a different name") {
                            for result in echoNestResults {
                                mockEchoNestService.mocker.prepareForCallTo(MockEchoNestService.Method.findSongs, returnValue: result)
                            }

                            playlistService.createPlaylist(numberOfSongs: numberOfSongs, songPreferences: arbitrarySongPreferences, callback: self.playlistCallback)
                            
                            expect(self.numberOfTimesFindSongsWasCalled(mockEchoNestService)).toEventually(equal(numberOfSongs + 1))
                            for contact in contactList {
                                expect(self.numberOfTimesFindSongsWasCalledForName(contact.firstName!, mockEchoNestService: mockEchoNestService)).to(equal(1))
                            }
                        }
                    }
                    
                    context("and the echo nest service calls back with an empty song result for one of the names") {
                        let numberOfSongs = contactList.count - 1
                        let echoNestResults: [EchoNestService.SongsResult] = [
                            .Success([Song(title: "title 1", artistName: "artist 1", uri: NSURL(string: "uri1")!)]),
                            .Success([Song]()),
                            .Success([Song(title: "title 2", artistName: "artist 2", uri: NSURL(string: "uri2")!)])]
                        
                        it("retries with a different name") {
                            for result in echoNestResults {
                                mockEchoNestService.mocker.prepareForCallTo(MockEchoNestService.Method.findSongs, returnValue: result)
                            }
                            
                            playlistService.createPlaylist(numberOfSongs: numberOfSongs, songPreferences: arbitrarySongPreferences, callback: self.playlistCallback)
                            
                            expect(self.numberOfTimesFindSongsWasCalled(mockEchoNestService)).toEventually(equal(numberOfSongs + 1))
                            for contact in contactList {
                                expect(self.numberOfTimesFindSongsWasCalledForName(contact.firstName!, mockEchoNestService: mockEchoNestService)).to(equal(1))
                            }
                        }
                    }
                    
                    context("and the echo nest service calls back with three errors") {
                        let numberOfSongs = contactList.count
                        let lastError = NSError(domain: "89", code: 89, userInfo: nil)
                        let echoNestResults: [EchoNestService.SongsResult] = [
                            .Failure(NSError(domain: "87", code: 87, userInfo: nil)),
                            .Failure(NSError(domain: "88", code: 88, userInfo: nil)),
                            .Failure(lastError)]
                        
                        it("calls back with the last error of the three") {
                            for result in echoNestResults {
                                mockEchoNestService.mocker.prepareForCallTo(MockEchoNestService.Method.findSongs, returnValue: result)
                            }
                            
                            playlistService.createPlaylist(numberOfSongs: numberOfSongs, songPreferences: arbitrarySongPreferences, callback: self.playlistCallback)
                            
                            expect(self.numberOfTimesFindSongsWasCalled(mockEchoNestService)).toEventually(equal(contactList.count))
                            expect(self.callbackErrorList.count).toEventually(equal(1))
                            expect(self.callbackErrorList[0]).toEventually(equal(lastError))
                            expect(self.callbackPlaylistList).to(beEmpty())
                        }
                    }
                    
                    context("and the echo nest service calls back with some duplicate songs") {
                        let numberOfSongs = contactList.count
                        let echoNestSongLists = [
                            [Song(title: "Johnny's Song", artistName: "artist 1", uri: NSURL(string: "uri1")!),
                                Song(title: "Johnny's Song 2", artistName: "artist 4", uri: NSURL(string: "uri4")!)],
                            [Song(title: "Billy's Song", artistName: "artist 2", uri: NSURL(string: "uri2")!),
                                Song(title: "Billy's Song 2", artistName: "artist 5", uri: NSURL(string: "uri5")!)],
                            [Song(title: "Johnny's Song", artistName: "artist 1", uri: NSURL(string: "uri1")!),
                                Song(title: "Johnny's Song 2", artistName: "artist 4", uri: NSURL(string: "uri4")!)]]
                        
                        beforeEach() {
                            for songList in echoNestSongLists {
                                mockEchoNestService.mocker.prepareForCallTo(MockEchoNestService.Method.findSongs, returnValue: EchoNestService.SongsResult.Success(songList))
                            }
                        }
                        
                        it("calls back with a playlist of the correct size with at least one unique song from each search result list") {
                            playlistService.createPlaylist(numberOfSongs: numberOfSongs, songPreferences: arbitrarySongPreferences, callback: self.playlistCallback)
                            
                            expect(self.callbackPlaylistList.count).toEventually(equal(1))
                            let playlistSongs = self.callbackPlaylistList.first!.songs
                            expect(playlistSongs.count).toEventually(equal(numberOfSongs))
                            let expectedSongs = [echoNestSongLists[0][0], echoNestSongLists[1][0], echoNestSongLists[2][0]]
                            for expectedSong in expectedSongs {
                                expect(playlistSongs).to(contain(expectedSong))
                            }
                        }
                    }
                    
                    context("and the desired number of songs requires more than half default echo nest search number parameter for each contact") {
                        let defaultSearchNumber = 20
                        let numberOfSongs = contactList.count * (defaultSearchNumber / 2 + 1)
                        
                        it("calls the echo nest service for each contact with double the minimum necessary search number") {
                            playlistService.createPlaylist(numberOfSongs: numberOfSongs, songPreferences: arbitrarySongPreferences, callback: self.playlistCallback)
                            
                            expect(self.numberOfTimesFindSongsWasCalled(mockEchoNestService)).toEventually(equal(contactList.count))
                            let expectedSearchNumber = (defaultSearchNumber / 2 + 1) * 2
                            for contact in contactList {
                                expect(self.numberOfTimesFindSongsWasCalledForName(contact.firstName!, mockEchoNestService: mockEchoNestService)).to(equal(1))
                                expect(self.numberRequestedFromFindSongsForName(contact.firstName!, callIndex: 0, mockEchoNestService: mockEchoNestService)).to(equal(expectedSearchNumber))
                            }
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
                        let echoNestResults: [EchoNestService.SongsResult] = [
                            .Success([Song(title: "title 1", artistName: "artist 1", uri: NSURL(string: "uri1")!)]),
                            .Failure(NSError(domain: "85", code: 87, userInfo: nil)),
                            .Failure(NSError(domain: "86", code: 88, userInfo: nil)),
                            .Failure(NSError(domain: "87", code: 87, userInfo: nil)),
                            .Failure(NSError(domain: "88", code: 88, userInfo: nil)),
                            .Failure(lastError)]
                        
                        it("calls back only with the first error over 20%") {
                            for result in echoNestResults {
                                mockEchoNestService.mocker.prepareForCallTo(MockEchoNestService.Method.findSongs, returnValue: result)
                            }
                            
                            playlistService.createPlaylist(numberOfSongs: numberOfSongs, songPreferences: arbitrarySongPreferences, callback: self.playlistCallback)
                            
                            expect(self.numberOfTimesFindSongsWasCalled(mockEchoNestService)).toEventually(equal(contactList.count))
                            expect(self.callbackErrorList.count).toEventually(equal(1))
                            expect(self.callbackErrorList.first).toEventually(equal(lastError))
                            expect(self.callbackPlaylistList).to(beEmpty())
                        }
                    }
                }
                
                context("when the contact service calls back with contacts not all of whom have first names") {
                    let contactList = [
                        Contact(id: 1, firstName: "Sylvester", lastName: "Stalone"),
                        Contact(id: 2, firstName: nil, lastName: "Schwarzenegger"),
                        Contact(id: 3, firstName: "", lastName: "Van Damme"),
                        Contact(id: 4, firstName: " \t\r\n", lastName: "Segal")]

                    beforeEach() {
                        mockContactService.mocker.prepareForCallTo(MockContactService.Method.retrieveAllContacts, returnValue: ContactService.ContactListResult.Success(contactList))
                    }
                    
                    it("only calls the echo nest service contacts that have a first name") {
                        let numberOfSongs = contactList.count
                        
                        playlistService.createPlaylist(numberOfSongs: numberOfSongs, songPreferences: arbitrarySongPreferences, callback: self.playlistCallback)
                        
                        expect(self.numberOfTimesFindSongsWasCalled(mockEchoNestService)).toEventually(equal(1))
                        expect(self.numberOfTimesFindSongsWasCalledForName(contactList.first!.firstName!, mockEchoNestService: mockEchoNestService)).to(equal(1))
                    }
                }
                
                context("when the contact service calls back with an empty list") {
                    let expectedError = NSError(domain: Constants.Error.Domain, code: Constants.Error.NoContactsCode, userInfo: [NSLocalizedDescriptionKey: Constants.Error.NoContactsMessage])
                    it("calls back with an appropriate error") {
                        mockContactService.mocker.prepareForCallTo(MockContactService.Method.retrieveAllContacts, returnValue: ContactService.ContactListResult.Success([]))
                        
                        playlistService.createPlaylist(numberOfSongs: 1, songPreferences: arbitrarySongPreferences, callback: self.playlistCallback)
                        
                        expect(self.callbackErrorList.count).toEventually(equal(1))
                        expect(self.callbackErrorList.first).toEventually(equal(expectedError))
                        expect(self.callbackPlaylistList).to(beEmpty())
                    }
                }
            }
        }
    }
    
    func numberOfTimesFindSongsWasCalled(mockEchoNestService: MockEchoNestService) -> Int {
        return mockEchoNestService.mocker.getCallCountFor(MockEchoNestService.Method.findSongs)
    }
    
    func numberOfTimesFindSongsWasCalledForName(name: String, mockEchoNestService: MockEchoNestService) -> Int {
        var numberOfCalls = 0
        if let findSongParameters = mockEchoNestService.mocker.recordedParameters[MockEchoNestService.Method.findSongs] {
            
            for parameters in findSongParameters {
                if let titleSearchTerm = parameters[0] as? String where titleSearchTerm == name {
                    numberOfCalls++
                }
            }
        }
        
        return numberOfCalls
    }
    
    func numberRequestedFromFindSongsForName(name: String, callIndex: Int = 0, mockEchoNestService: MockEchoNestService) -> Int? {
        var number: Int?
        if let findSongParameters = mockEchoNestService.mocker.recordedParameters[MockEchoNestService.Method.findSongs] {
            
            for parameters in findSongParameters {
                if let titleSearchTerm = parameters[0] as? String where titleSearchTerm == name {
                    number = (parameters[1] as! Int)
                }
            }
        }
        
        return number
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