import Foundation
import Quick
import Nimble

class SpotifySpikeSpec: QuickSpec {
    
    var listPage: SPTListPage?
    
    override func spec() {
        xit("Retrieving tracks from the spotify service") {
            
            SPTRequest.performSearchWithQuery("track:Clair%20year:1900-2000"
                , queryType: .QueryTypeTrack, session: nil, //market: "US",
                callback: { (error, list) -> Void in
                if (error != nil) {
                    println("error : \(error)")
                }
                println("list : \(list)")
                self.listPage = list as? SPTListPage

            })

            expect(self.listPage).toEventuallyNot(beNil(), timeout: 3)
            println("listPage : \(self.listPage)")
            println("totalListLength : \(self.listPage?.totalListLength)")
            if let page = self.listPage {
                expect(self.listPage?.items).toEventuallyNot(beNil())
            
                if let items = self.listPage?.items {
                    expect(self.listPage?.items.count).toEventually(beGreaterThan(0))
                    for item in items {
                        var partialTrack = item as SPTPartialTrack
                        println("partialTrack : \(partialTrack)")
                    }
                }
                
                expect(page.hasNextPage).to(beTrue())
                if page.hasNextPage {
                    page.requestNextPageWithSession(nil,
                        callback: { (error, list) -> Void in
                            if (error != nil) {
                                println("error : \(error)")
                            }
                            println("nextPage list : \(list)")
                            self.listPage = list as? SPTListPage
                    })
                    
                    expect(self.listPage).toEventuallyNot(beNil())
                    println("nextPage listPage : \(self.listPage)")
                    println("nextPage totalListLength : \(self.listPage?.totalListLength)")
                }
            }

        }
    }
}
