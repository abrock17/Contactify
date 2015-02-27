import Contactify
import Foundation
import Quick
import Nimble

let arbitrarySongTitleSearchTerm = "song"

class EchoNestServiceSpec: QuickSpec {
    
    var callbackSongData: SongData?
    var callbackError: NSError?
    
    func findSongDataCompletionHandler (songData: SongData?, error: NSError!) -> Void {
        callbackSongData = songData
        callbackError = error
    }
    
    override func spec() {
        describe("The EchoNestService") {
            var echoNestService: EchoNestService?
            let mockURLConnection = MockURLConnectionWrapper()
            beforeEach() {
                echoNestService = EchoNestService(urlConnectionWrapper: mockURLConnection)
            }
            
            describe("find song data for title search term") {
                context("when no song is found") {
                    self.callbackSongData = SongData(title: "non-nil song so we can check for nil later", artistName: nil, catalogID: nil)
                    
                    it("song data is nil") {
                        echoNestService!.findSongData(titleSearchTerm: arbitrarySongTitleSearchTerm, completionHandler: self.findSongDataCompletionHandler)
                        expect(self.callbackSongData).toEventually(beNil())
                    }
                }
                
                context("when the underlying URL connection returns an error") {
                    let expectedError = NSError(domain: "ERROR:", code: 1, userInfo: nil)
                    mockURLConnection.error = expectedError
                    
                    it("passes back the same error") {
                        echoNestService!.findSongData(titleSearchTerm: arbitrarySongTitleSearchTerm, completionHandler: self.findSongDataCompletionHandler)
                        expect(self.callbackError).toEventually(equal(expectedError))
                    }
                }
            }
        }
    }
}

class MockURLConnectionWrapper: NSURLConnectionWrapper {
    
    var response: NSURLResponse?
    var data: NSData?
    var error: NSError?
    
    override func sendAsynchronousRequest(request: NSURLRequest, queue: NSOperationQueue!, completionHandler handler: (NSURLResponse!, NSData!, NSError!) -> Void) {
        handler(response, data, error)
    }
}