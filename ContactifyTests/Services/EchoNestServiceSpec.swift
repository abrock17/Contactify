import Contactify
import Foundation
import Alamofire
import Quick
import Nimble

let arbitrarySongTitleSearchTerm = "Susie"

class EchoNestServiceSpec: QuickSpec {
    
    var callbackSongData: SongData?
    var callbackError: NSError?
    
    func findSongDataCompletionHandler (songDataResult: EchoNestService.SongDataResult) {
        switch (songDataResult) {
        case .Success(let songData):
            callbackSongData = songData
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
                    it("contains the correct title string") {
                        echoNestService!.findSongData(titleSearchTerm: arbitrarySongTitleSearchTerm, completionHandler: self.findSongDataCompletionHandler)

                        expect(MockURLProtocol.getCapturedRequest()?.URL.absoluteString).toEventually(contain("title=Susie"))
                    }
                }
                
                context("when the search term has special characters") {
                    it("is encoded in the URL request") {
                        echoNestService!.findSongData(titleSearchTerm: "\"Special, Characters ... (&)\"", completionHandler: self.findSongDataCompletionHandler)
                        
                        expect(MockURLProtocol.getCapturedRequest()?.URL.absoluteString).toEventually(contain("title=%22Special%2C%20Characters%20...%20%28%26%29%22"))
                    }
                }
                
                context("when the underlying URL connection returns no data") {
                    it("calls back with nil SongData") {
                        self.callbackSongData = SongData(title: "non-nil song so we can check for nil later", artistName: nil, catalogID: nil)
                        MockURLProtocol.setMockResponseData("".dataUsingEncoding(NSUTF8StringEncoding))
                        echoNestService!.findSongData(titleSearchTerm: arbitrarySongTitleSearchTerm, completionHandler: self.findSongDataCompletionHandler)

                        expect(self.callbackSongData).toEventually(beNil())
                    }
                }
                
                context("when the underlying URL connection returns an error") {
                    let expectedError = NSError(domain: "MockError", code: 99999, userInfo: nil)
                    
                    it("passes back the same error") {
                        MockURLProtocol.setMockError(expectedError)
                        echoNestService!.findSongData(titleSearchTerm: arbitrarySongTitleSearchTerm, completionHandler: self.findSongDataCompletionHandler)

                        expect(self.callbackError?.domain).toEventually(equal(expectedError.domain))
                        expect(self.callbackError?.code).toEventually(equal(expectedError.code))
                    }
                }
                
                context("when a song is found") {
                    let url = NSBundle(forClass: EchoNestServiceSpec.self).URLForResource("echonest-response-data-one-song", withExtension: "txt")
                    let data = NSData(contentsOfURL: url!)
                    
                    beforeEach() {
                        MockURLProtocol.setMockResponseData(data)
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

