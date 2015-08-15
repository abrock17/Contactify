import TuneThatName
import Foundation
import Alamofire
import Quick
import Nimble


class EchoNestServiceSpec: QuickSpec {
    
    var callbackSongs = [Song]()
    var callbackError: NSError?
    
    func findSongsCallback (songResult: EchoNestService.SongsResult) {
        switch (songResult) {
        case .Success(let songs):
            callbackSongs = songs
        case .Failure(let error):
            callbackError = error
        }
    }
    
    let arbitrarySongTitleSearchTerm = "Susie"
    let arbitrarySongPreferences = SongPreferences(favorPopular: true, favorPositive: false, favorNegative: false)

    override func spec() {
        
        describe("The Echo Nest Service") {
            var echoNestService: EchoNestService!
            
            beforeEach() {
                self.callbackSongs.removeAll(keepCapacity: false)
                self.callbackError = nil

                let urlSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
                urlSessionConfiguration.protocolClasses?.insert(MockURLProtocol.self, atIndex: 0)
                let alamoFireManager = Manager(configuration: urlSessionConfiguration)
                
                echoNestService = EchoNestService(alamoFireManager: alamoFireManager)
            }
            
            afterEach() {
                MockURLProtocol.clear()
            }
            
            describe("find songs for title search term") {
                context("when performing a search") {
                    beforeEach() {
                        echoNestService.findSongs(titleSearchTerm: self.arbitrarySongTitleSearchTerm, songPreferences: self.arbitrarySongPreferences, desiredNumberOfSongs: 1, callback: self.findSongsCallback)
                    }
                    
                    it("creates a request that contains the correct title string") {
                        expect(MockURLProtocol.getCapturedRequest()?.URL!.absoluteString)
                            .toEventually(contain("title=Susie"))
                    }
                    
                    it("creates a request that contains the expected bucket parameters") {
                        expect(MockURLProtocol.getCapturedRequest()?.URL!.absoluteString)
                            .toEventually(contain("bucket=tracks"))
                        expect(MockURLProtocol.getCapturedRequest()?.URL!.absoluteString)
                            .toEventually(contain("bucket=id:spotify"))
                        expect(MockURLProtocol.getCapturedRequest()?.URL!.absoluteString)
                            .toEventually(contain("bucket=song_discovery"))
                        expect(MockURLProtocol.getCapturedRequest()?.URL!.absoluteString)
                            .toEventually(contain("bucket=artist_discovery"))
                    }
                    
                    it("creates a request that contains the default 'results' parameter") {
                        expect(MockURLProtocol.getCapturedRequest()?.URL!.absoluteString)
                            .toEventually(contain("results=50"))
                    }
                }
                
                context("when the song preferences favor popular songs") {
                    it("creates a request that sorts by song hotttnesss descending") {
                        echoNestService.findSongs(titleSearchTerm: self.arbitrarySongTitleSearchTerm, songPreferences: SongPreferences(favorPopular: true, favorPositive: false, favorNegative: false), desiredNumberOfSongs: 1, callback: self.findSongsCallback)

                        expect(MockURLProtocol.getCapturedRequest()?.URL?.absoluteString)
                            .toEventually(contain("sort=song_hotttnesss-desc"))
                    }
                }
                
                context("when the song preferences favor positive songs") {
                    it("creates a request that has a min valence parameter of 0.5") {
                        echoNestService.findSongs(titleSearchTerm: self.arbitrarySongTitleSearchTerm, songPreferences: SongPreferences(favorPopular: false, favorPositive: true, favorNegative: false), desiredNumberOfSongs: 1, callback: self.findSongsCallback)
                        
                        expect(MockURLProtocol.getCapturedRequest()?.URL?.absoluteString)
                            .toEventually(contain("min_valence=0.5"))
                    }
                }
                
                context("when the song preferences favor negative songs") {
                    it("creates a request that has a max valence parameter of 0.5") {
                        echoNestService.findSongs(titleSearchTerm: self.arbitrarySongTitleSearchTerm, songPreferences: SongPreferences(favorPopular: false, favorPositive: false, favorNegative: true), desiredNumberOfSongs: 1, callback: self.findSongsCallback)
                        
                        expect(MockURLProtocol.getCapturedRequest()?.URL?.absoluteString)
                            .toEventually(contain("max_valence=0.5"))
                    }
                }
                
                context("when the song preferences favor neither negative or positive songs") {
                    it("creates a request that makes no mention of the valence parameter") {
                        echoNestService.findSongs(titleSearchTerm: self.arbitrarySongTitleSearchTerm, songPreferences: SongPreferences(favorPopular: false, favorPositive: false, favorNegative: false), desiredNumberOfSongs: 1, callback: self.findSongsCallback)
                        
                        expect(MockURLProtocol.getCapturedRequest()?.URL?.absoluteString)
                            .toEventuallyNot(contain("valence"))
                    }
                }
                
                context("when the desired number of songs is greater than half the default search number") {
                    it("creates a request that contains a 'results' parameter double the necessary minimum") {
                        echoNestService.findSongs(titleSearchTerm: self.arbitrarySongTitleSearchTerm, songPreferences: self.arbitrarySongPreferences, desiredNumberOfSongs: 26, callback: self.findSongsCallback)
                        
                        expect(MockURLProtocol.getCapturedRequest()?.URL!.absoluteString)
                            .toEventually(contain("results=52"))
                    }
                }
                
                context("when the desired number of songs is greater than half the max results number") {
                    it("creates a request that contains the max 'results' parameter") {
                        echoNestService.findSongs(titleSearchTerm: self.arbitrarySongTitleSearchTerm, songPreferences: self.arbitrarySongPreferences, desiredNumberOfSongs: 51, callback: self.findSongsCallback)
                        
                        expect(MockURLProtocol.getCapturedRequest()?.URL!.absoluteString)
                            .toEventually(contain("results=100"))
                    }
                }
                
                context("when the search term has special characters") {
                    it("encodeds them propery in the URL request") {
                        echoNestService.findSongs(titleSearchTerm: "\"Special, Characters ... (&)\"", songPreferences: self.arbitrarySongPreferences, desiredNumberOfSongs: 1, callback: self.findSongsCallback)
                        
                        expect(MockURLProtocol.getCapturedRequest()?.URL!.absoluteString)
                            .toEventually(contain("title=%22Special%2C%20Characters%20...%20%28%26%29%22"))
                    }
                }
                
                context("when the underlying URL connection returns no data") {
                    it("calls back with a generic error message") {
                        MockURLProtocol.setMockResponseData("".dataUsingEncoding(NSUTF8StringEncoding))
                        
                        echoNestService.findSongs(titleSearchTerm: self.arbitrarySongTitleSearchTerm, songPreferences: self.arbitrarySongPreferences, desiredNumberOfSongs: 1, callback: self.findSongsCallback)
                        
                        expect(self.callbackError?.domain).toEventually(equal(Constants.Error.Domain))
                        expect(self.callbackError?.userInfo?[NSLocalizedDescriptionKey] as? String).toEventually(equal("Unexpected response from the Echo Nest."))
                    }
                }
                
                context("when the underlying URL connection returns an error") {
                    let expectedError = NSError(domain: "MockError", code: 99999, userInfo: nil)
                    
                    it("passes back the same error") {
                        MockURLProtocol.setMockError(expectedError)
                        
                        echoNestService.findSongs(titleSearchTerm: self.arbitrarySongTitleSearchTerm, songPreferences: self.arbitrarySongPreferences, desiredNumberOfSongs: 1, callback: self.findSongsCallback)
                        
                        expect(self.callbackError?.domain).toEventually(equal(expectedError.domain))
                        expect(self.callbackError?.code).toEventually(equal(expectedError.code))
                    }
                }
                
                context("when the response data status is not successful") {
                    let url = NSBundle(forClass: EchoNestServiceSpec.self).URLForResource("echonest-response-data-timeout-error", withExtension: "txt")
                    let data = NSData(contentsOfURL: url!)
                    
                    it("calls back with an error with the status message") {
                        MockURLProtocol.setMockResponseData(data)
                        
                        echoNestService.findSongs(titleSearchTerm: self.arbitrarySongTitleSearchTerm, songPreferences: self.arbitrarySongPreferences, desiredNumberOfSongs: 1, callback: self.findSongsCallback)
                        
                        expect(self.callbackError?.domain).toEventually(equal(Constants.Error.Domain))
                        expect(self.callbackError?.userInfo?[NSLocalizedDescriptionKey] as? String).toEventually(equal("Non-zero status code from the Echo Nest."))
                        expect(self.callbackError?.userInfo?[NSLocalizedFailureReasonErrorKey] as? String).toEventually(equal("The operation timed out"))
                    }
                }

                context("when no songs are found") {
                    let url = NSBundle(forClass: EchoNestServiceSpec.self).URLForResource("echonest-response-data-no-songs", withExtension: "txt")
                    let data = NSData(contentsOfURL: url!)
                    
                    beforeEach() {
                        MockURLProtocol.setMockResponseData(data)
                    }
                    
                    it("calls back with an empty song array") {
                        self.callbackSongs.append(Song(title: "non-empty song list so we can check for empty later", artistName: nil, uri: NSURL(string: "uri")!))
                        
                        echoNestService.findSongs(titleSearchTerm: self.arbitrarySongTitleSearchTerm, songPreferences: self.arbitrarySongPreferences, desiredNumberOfSongs: 1, callback: self.findSongsCallback)
                        
                        expect(self.callbackSongs).toEventually(beEmpty())
                    }
                }
                
                context("when one song is requested and found") {
                    let url = NSBundle(forClass: EchoNestServiceSpec.self).URLForResource("echonest-response-data-one-song", withExtension: "txt")
                    let data = NSData(contentsOfURL: url!)
                    
                    beforeEach() {
                        MockURLProtocol.setMockResponseData(data)
                        echoNestService.findSongs(titleSearchTerm: self.arbitrarySongTitleSearchTerm, songPreferences: self.arbitrarySongPreferences, desiredNumberOfSongs: 1, callback: self.findSongsCallback)
                    }
                    
                    it("calls back with a song") {
                        expect(self.callbackSongs.count).toEventually(equal(1))
                    }
                    
                    it("has the expected title") {
                        expect(self.callbackSongs.count).toEventually(equal(1))
                        expect(self.callbackSongs[0].title).to(equal("Susie Q"))
                    }
                    
                    it("has the expected artist name") {
                        expect(self.callbackSongs.count).toEventually(equal(1))
                        expect(self.callbackSongs[0].displayArtistName).to(equal("Creedence Clearwater Revival"))
                    }
                    
                    it("has the expected uri") {
                        expect(self.callbackSongs.count).toEventually(equal(1))
                        expect(self.callbackSongs[0].uri).to(equal(NSURL(string: "spotify:track:38kWGB8ab6UflBPWQcQ8Ua")))
                    }
                }
                
                context("when only one song with no foreign catalog ID is found") {
                    self.callbackSongs.append(Song(title: "non-nil song so we can check for nil later", artistName: nil, uri: NSURL(string: "uri")!))
                    let url = NSBundle(forClass: EchoNestServiceSpec.self).URLForResource("echonest-response-data-one-song-no-foreign_id", withExtension: "txt")
                    let data = NSData(contentsOfURL: url!)
                    
                    it("calls back with nil Song") {
                        MockURLProtocol.setMockResponseData(data)
                        
                        echoNestService.findSongs(titleSearchTerm: self.arbitrarySongTitleSearchTerm, songPreferences: self.arbitrarySongPreferences, desiredNumberOfSongs: 1, callback: self.findSongsCallback)
                        
                        expect(self.callbackSongs).toEventually(beEmpty())
                    }
                }

                context("when multiple songs are found and only the last one contains the word as part of the actual title") {
                    let url = NSBundle(forClass: EchoNestServiceSpec.self).URLForResource("echonest-response-data-multiple-songs-with-incorrect-title", withExtension: "txt")
                    let data = NSData(contentsOfURL: url!)
                    
                    it("calls back with the expected song") {
                        MockURLProtocol.setMockResponseData(data)
                        
                        echoNestService.findSongs(titleSearchTerm: self.arbitrarySongTitleSearchTerm, songPreferences: self.arbitrarySongPreferences, desiredNumberOfSongs: 1, callback: self.findSongsCallback)
                        
                        expect(self.callbackSongs.count).toEventually(equal(1))
                        expect(self.callbackSongs[0].title).toEventually(equal("Susie Q"))
                    }
                }

                context("when multiple songs are requested") {
                    let numberOfSongs = 4
                    
                    context("and are found") {
                        let url = NSBundle(forClass: EchoNestServiceSpec.self).URLForResource("echonest-response-data-multiple-songs", withExtension: "txt")
                        let data = NSData(contentsOfURL: url!)
                        
                        beforeEach() {
                            MockURLProtocol.setMockResponseData(data)
                            
                            echoNestService.findSongs(titleSearchTerm: self.arbitrarySongTitleSearchTerm, songPreferences: self.arbitrarySongPreferences, desiredNumberOfSongs: numberOfSongs, callback: self.findSongsCallback)
                        }
                        
                        it("calls back with the requested number of songs") {
                            expect(self.callbackSongs.count).toEventually(equal(numberOfSongs))
                            expect(self.callbackError).to(beNil())
                        }
                        
                        it("contains the expected artists (no duplicates)") {
                            expect(self.callbackSongs.count).toEventually(equal(numberOfSongs))
                            expect(self.callbackSongs[0].displayArtistName).to(equal("La Vella Dixieland"))
                            expect(self.callbackSongs[1].displayArtistName).to(equal("Goulam S.K."))
                            expect(self.callbackSongs[2].displayArtistName).to(equal("Hy3rid"))
                            expect(self.callbackSongs[3].displayArtistName).to(equal("Raul Bercianos"))
                        }
                    }
                    
                    context("and song preferences do not favor popular songs") {
                        let url = NSBundle(forClass: EchoNestServiceSpec.self).URLForResource("echonest-response-data-songs-with-discovery", withExtension: "txt")
                        let data = NSData(contentsOfURL: url!)
                        let songPreferences = SongPreferences(favorPopular: false, favorPositive: false, favorNegative: false)
                        
                        it("calls back with songs sorted by a combination of song and artist discovery") {
                            MockURLProtocol.setMockResponseData(data)
                            
                            echoNestService.findSongs(titleSearchTerm: self.arbitrarySongTitleSearchTerm, songPreferences: songPreferences, desiredNumberOfSongs: numberOfSongs, callback: self.findSongsCallback)
                            
                            let expectedSortedSongs = [
                                Song(title: "Janet", artistName: "Just Paul", uri: NSURL(string: "spotify:track:3PJmjxPVW2Hv4voMmmceeI")!),
                                Song(title: "Janet", artistName: "Katie Noonan", uri: NSURL(string: "spotify:track:7eFetxLmsMGRunBDTA3DG3")!),
                                Song(title: "Janet", artistName: "Ned Collette", uri: NSURL(string: "spotify:track:0m21XB7kygO43mrmkPtazy")!),
                                Song(title: "Janet", artistName: "Philip Catherine", uri: NSURL(string: "spotify:track:0UWGq0ddfPc2KDC3NDdJ8q")!),
                                ]
                            expect(self.callbackSongs).toEventually(equal(expectedSortedSongs))
                        }
                    }
                }
            }
        }
    }
}

