import TuneThatName
import Foundation
import Alamofire
import Quick
import Nimble

let arbitrarySongTitleSearchTerm = "Susie"

class EchoNestServiceSpec: QuickSpec {
    
    var callbackSong: Song?
    var callbackError: NSError?
    
    func findSongCallback (songResult: EchoNestService.SongResult) {
        switch (songResult) {
        case .Success(let song):
            callbackSong = song
        case .Failure(let error):
            callbackError = error
        }
    }
    
    override func spec() {
        
        describe("The EchoNestService") {
            var echoNestService: EchoNestService!
            
            beforeEach() {
                self.callbackSong = nil
                self.callbackError = nil

                let urlSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
                urlSessionConfiguration.protocolClasses?.insert(MockURLProtocol.self, atIndex: 0)
                let alamoFireManager = Manager(configuration: urlSessionConfiguration)
                
                echoNestService = EchoNestService(alamoFireManager: alamoFireManager)
            }
            
            afterEach() {
                MockURLProtocol.clear()
            }
            
            describe("find song data for title search term") {

                context("when performing a search") {
                    beforeEach() {
                        echoNestService.findSong(titleSearchTerm: arbitrarySongTitleSearchTerm, callback: self.findSongCallback)
                    }
                    
                    it("contains the correct title string") {
                        expect(MockURLProtocol.getCapturedRequest()?.URL!.absoluteString).toEventually(contain("title=Susie"))
                    }
                    
                    it("contains the expected bucket parameters") {
                        expect(MockURLProtocol.getCapturedRequest()?.URL!.absoluteString).toEventually(contain("bucket=tracks"))
                        expect(MockURLProtocol.getCapturedRequest()?.URL!.absoluteString).toEventually(contain("bucket=id:spotify"))
                    }
                }
                
                context("when the search term has special characters") {
                    it("is encoded in the URL request") {
                        echoNestService.findSong(titleSearchTerm: "\"Special, Characters ... (&)\"", callback: self.findSongCallback)
                        
                        expect(MockURLProtocol.getCapturedRequest()?.URL!.absoluteString).toEventually(contain("title=%22Special%2C%20Characters%20...%20%28%26%29%22"))
                    }
                }
                
                context("when the underlying URL connection returns no data") {
                    it("calls back with a generic error message") {
                        MockURLProtocol.setMockResponseData("".dataUsingEncoding(NSUTF8StringEncoding))
                        
                        echoNestService.findSong(titleSearchTerm: arbitrarySongTitleSearchTerm, callback: self.findSongCallback)

                        expect(self.callbackError?.domain).toEventually(equal(Constants.Error.Domain))
                        expect(self.callbackError?.userInfo?[NSLocalizedDescriptionKey] as? String).toEventually(equal("Unexpected response from the Echo Nest."))
                    }
                }
                
                context("when the underlying URL connection returns an error") {
                    let expectedError = NSError(domain: "MockError", code: 99999, userInfo: nil)
                    
                    it("passes back the same error") {
                        MockURLProtocol.setMockError(expectedError)
                        echoNestService.findSong(titleSearchTerm: arbitrarySongTitleSearchTerm, callback: self.findSongCallback)

                        expect(self.callbackError?.domain).toEventually(equal(expectedError.domain))
                        expect(self.callbackError?.code).toEventually(equal(expectedError.code))
                    }
                }
                
                context("when the response data status is not successful") {
                    let url = NSBundle(forClass: EchoNestServiceSpec.self).URLForResource("echonest-response-data-timeout-error", withExtension: "txt")
                    let data = NSData(contentsOfURL: url!)

                    it("calls back with an error with the status message") {
                        MockURLProtocol.setMockResponseData(data)
                        echoNestService.findSong(titleSearchTerm: arbitrarySongTitleSearchTerm, callback: self.findSongCallback)
                        
                        expect(self.callbackError?.domain).toEventually(equal(Constants.Error.Domain))
                        expect(self.callbackError?.userInfo?[NSLocalizedDescriptionKey] as? String).toEventually(equal("Non-zero status code from the Echo Nest."))
                        expect(self.callbackError?.userInfo?[NSLocalizedFailureReasonErrorKey] as? String).toEventually(equal("The operation timed out"))
                    }
                }
                
                context("when a song is found") {
                    let url = NSBundle(forClass: EchoNestServiceSpec.self).URLForResource("echonest-response-data-one-song", withExtension: "txt")
                    let data = NSData(contentsOfURL: url!)
                    
                    beforeEach() {
                        MockURLProtocol.setMockResponseData(data)
                        echoNestService.findSong(titleSearchTerm: arbitrarySongTitleSearchTerm, callback: self.findSongCallback)
                    }
                    
                    it("calls back with song data") {
                        expect(self.callbackSong).toEventuallyNot(beNil())
                    }
                    
                    it("has the expected title") {
                        expect(self.callbackSong?.title).toEventually(equal("Susie Q"))
                    }
                    
                    it("has the expected artist name") {
                        expect(self.callbackSong?.artistName).toEventually(equal("Creedence Clearwater Revival"))
                    }
                    
                    it("has the expected uri") {
                        expect(self.callbackSong?.uri).toEventually(equal(NSURL(string: "spotify:track:38kWGB8ab6UflBPWQcQ8Ua")))
                    }
                }
                
                context("when only a song with no foreign catalog ID is found") {
                    self.callbackSong = Song(title: "non-nil song so we can check for nil later", artistName: nil, uri: nil)
                    let url = NSBundle(forClass: EchoNestServiceSpec.self).URLForResource("echonest-response-data-one-song-no-foreign_id", withExtension: "txt")
                    let data = NSData(contentsOfURL: url!)
                    
                    it("calls back with nil Song") {
                        MockURLProtocol.setMockResponseData(data)

                        echoNestService.findSong(titleSearchTerm: arbitrarySongTitleSearchTerm, callback: self.findSongCallback)
                        
                        expect(self.callbackSong).toEventually(beNil())
                    }
                }
                
                context("when multiple songs are found and only the last one contains the word as part of the actual title") {
                    let url = NSBundle(forClass: EchoNestServiceSpec.self).URLForResource("echonest-response-data-multiple-songs-with-incorrect-title", withExtension: "txt")
                    let data = NSData(contentsOfURL: url!)
                    
                    it("calls back with the expected song") {
                        MockURLProtocol.setMockResponseData(data)
                        echoNestService.findSong(titleSearchTerm: arbitrarySongTitleSearchTerm, callback: self.findSongCallback)

                        expect(self.callbackSong).toEventuallyNot(beNil())
                        expect(self.callbackSong?.title).toEventually(equal("Susie Q"))
                    }
                }
            }
        }
    }
}

