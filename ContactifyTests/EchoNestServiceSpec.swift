import Contactify
import Foundation
import Quick
import Nimble

let arbitrarySongTitleSearchTerm = "Susie"

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
            var mockURLConnection: MockURLConnectionWrapper?
            
            beforeEach() {
                mockURLConnection = MockURLConnectionWrapper(response: NSURLResponse(), data: "".dataUsingEncoding(NSUTF8StringEncoding), error: NSError())
                echoNestService = EchoNestService(urlConnectionWrapper: mockURLConnection!)
            }
            
            describe("find song data for title search term") {
                context("when performing a search") {
                    beforeEach() {
                        echoNestService!.findSongData(titleSearchTerm: arbitrarySongTitleSearchTerm, completionHandler: self.findSongDataCompletionHandler)
                    }
                    
                    it("uses the correct URL string") {
                        expect(mockURLConnection?.request?.URL.absoluteString).toEventually(equal("http://developer.echonest.com/api/v4/song/search?api_key=GVZ7FFJUMMXBG58VQ&format=json&results=50&sort=song_hotttnesss-desc&limit=true&title=Susie&bucket=tracks&bucket=id:spotify"))
                    }
                }
                
                context("when the search term has special characters") {
                    beforeEach() {
                        echoNestService!.findSongData(titleSearchTerm: "X Y$Z%&1#2(3)4[5]6{7}8\"9\"", completionHandler: self.findSongDataCompletionHandler)
                    }
                    
                    it("is encoded in the URL request") {
                        expect(mockURLConnection?.request?.URL.absoluteString).toEventually(contain("title=X%20Y$Z%25&1%232(3)4%5B5%5D6%7B7%7D8%229%22"))
                    }
                }
                
                context("when the underlying URL connection returns no data") {
                    beforeEach() {
                        self.callbackSongData = SongData(title: "non-nil song so we can check for nil later", artistName: nil, catalogID: nil)
                        echoNestService!.findSongData(titleSearchTerm: arbitrarySongTitleSearchTerm, completionHandler: self.findSongDataCompletionHandler)
                    }
                    
                    it("calls back with nil SongData") {

                        expect(self.callbackSongData).toEventually(beNil())
                    }
                }
                
                context("when the underlying URL connection returns an error") {
                    let expectedError = NSError(domain: "ERROR:", code: 1, userInfo: nil)
                    
                    beforeEach() {
                        mockURLConnection!.error = expectedError
                        echoNestService!.findSongData(titleSearchTerm: arbitrarySongTitleSearchTerm, completionHandler: self.findSongDataCompletionHandler)
                    }
                    
                    it("passes back the same error") {
                        expect(self.callbackError).toEventually(equal(expectedError))
                    }
                }
                
                context("when a song is found") {
                    let url = NSBundle(forClass: EchoNestServiceSpec.self).URLForResource("echonest-response-data-one-song", withExtension: "txt")
                    let data = NSData(contentsOfURL: url!)
                    
                    beforeEach() {
                        mockURLConnection!.data = data
                        echoNestService!.findSongData(titleSearchTerm: arbitrarySongTitleSearchTerm, completionHandler: self.findSongDataCompletionHandler)
                    }
                    
                    it("calls back with song data") {
                        expect(self.callbackSongData).toEventuallyNot(beNil())
                    }
                    
                    it("has the expected title") {
                        expect(self.callbackSongData?.title).toEventually(equal("Susie Q"))
                    }
                    
                    it("has the expected artist name") {
                        expect(self.callbackSongData?.artistName).toEventually(equal("Creedence Clearwater Revival"))
                    }
                }
            }
        }
    }
}

class MockURLConnectionWrapper: NSURLConnectionWrapper {
    
    var response: NSURLResponse!
    var data: NSData!
    var error: NSError!
    var request: NSURLRequest?
    
    init(response: NSURLResponse!, data: NSData!, error: NSError!) {
        self.response = response
        self.data = data
        self.error = error
        super.init()
    }
    
    override func sendAsynchronousRequest(request: NSURLRequest, queue: NSOperationQueue!, completionHandler handler: (NSURLResponse!, NSData!, NSError!) -> Void) {
        self.request = request
        handler(response, data, error)
    }
}