import TuneThatName
import Foundation
import Alamofire
import Quick
import Nimble

let arbitrarySongTitleSearchTerm = "Susie"

class EchoNestServiceSpec: QuickSpec {
    
    var callbackSong: Song?
    var callbackError: NSError?
    
    func findSongCompletionHandler (songResult: EchoNestService.SongResult) {
        switch (songResult) {
        case .Success(let song):
            callbackSong = song
        case .Failure(let error):
            callbackError = error
        }
    }
    
    override func spec() {
        
        describe("The EchoNestService") {
            var echoNestService: EchoNestService?
            
            beforeEach() {
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
                        echoNestService!.findSong(titleSearchTerm: arbitrarySongTitleSearchTerm, completionHandler: self.findSongCompletionHandler)
                    }
                    
                    it("contains the correct title string") {
                        expect(MockURLProtocol.getCapturedRequest()?.URL.absoluteString).toEventually(contain("title=Susie"))
                    }
                    
                    it("contains the expected bucket parameters") {
                        expect(MockURLProtocol.getCapturedRequest()?.URL.absoluteString).toEventually(contain("bucket=tracks"))
                        expect(MockURLProtocol.getCapturedRequest()?.URL.absoluteString).toEventually(contain("bucket=id:spotify"))
                    }
                }
                
                context("when the search term has special characters") {
                    it("is encoded in the URL request") {
                        echoNestService!.findSong(titleSearchTerm: "\"Special, Characters ... (&)\"", completionHandler: self.findSongCompletionHandler)
                        
                        expect(MockURLProtocol.getCapturedRequest()?.URL.absoluteString).toEventually(contain("title=%22Special%2C%20Characters%20...%20%28%26%29%22"))
                    }
                }
                
                context("when the underlying URL connection returns no data") {
                    it("calls back with nil Song") {
                        self.callbackSong = Song(title: "non-nil song so we can check for nil later", artistName: nil, catalogID: nil)
                        MockURLProtocol.setMockResponseData("".dataUsingEncoding(NSUTF8StringEncoding))
                        echoNestService!.findSong(titleSearchTerm: arbitrarySongTitleSearchTerm, completionHandler: self.findSongCompletionHandler)

                        expect(self.callbackSong).toEventually(beNil())
                    }
                }
                
                context("when the underlying URL connection returns an error") {
                    let expectedError = NSError(domain: "MockError", code: 99999, userInfo: nil)
                    
                    it("passes back the same error") {
                        MockURLProtocol.setMockError(expectedError)
                        echoNestService!.findSong(titleSearchTerm: arbitrarySongTitleSearchTerm, completionHandler: self.findSongCompletionHandler)

                        expect(self.callbackError?.domain).toEventually(equal(expectedError.domain))
                        expect(self.callbackError?.code).toEventually(equal(expectedError.code))
                    }
                }
                
                context("when a song is found") {
                    let url = NSBundle(forClass: EchoNestServiceSpec.self).URLForResource("echonest-response-data-one-song", withExtension: "txt")
                    let data = NSData(contentsOfURL: url!)
                    
                    beforeEach() {
                        MockURLProtocol.setMockResponseData(data)
                        echoNestService!.findSong(titleSearchTerm: arbitrarySongTitleSearchTerm, completionHandler: self.findSongCompletionHandler)
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
                }
                
                context("when multiple songs are found and only the last one contains the word as part of the actual title") {
                    let url = NSBundle(forClass: EchoNestServiceSpec.self).URLForResource("echonest-response-data-multiple-songs-with-incorrect-title", withExtension: "txt")
                    let data = NSData(contentsOfURL: url!)
                    
                    it("calls back with the expected song") {
                        MockURLProtocol.setMockResponseData(data)
                        echoNestService!.findSong(titleSearchTerm: arbitrarySongTitleSearchTerm, completionHandler: self.findSongCompletionHandler)

                        expect(self.callbackSong).toEventuallyNot(beNil())
                        expect(self.callbackSong?.title).toEventually(equal("Susie Q"))
                    }
                }
            }
        }
    }
}

