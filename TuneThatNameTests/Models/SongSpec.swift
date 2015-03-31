import TuneThatName
import Foundation
import Quick
import Nimble

class SongSpec: QuickSpec {
    let arbitraryURI = NSURL(string: "spotify:track:6N2sQ0wEgKMEHdwnYdJuDy")
    
    override func spec() {
        describe("equality") {
            
            it("are not equal when title doesn't match") {
                expect(Song(title: "x", artistName: "artist", uri: nil))
                    .toNot(equal(Song(title: "y", artistName: "artist2", uri: nil)))
            }
            
            it("are not equal when uri doesn't match") {
                expect(Song(title: "x", artistName: "artist", uri: self.arbitraryURI))
                    .toNot(equal(Song(title: "x", artistName: "artist2", uri: nil)))
            }
            
            it("are equal when title and uri match") {
                expect(Song(title: "x", artistName: "artist", uri: self.arbitraryURI))
                    .to(equal(Song(title: "x", artistName: "artist2", uri: self.arbitraryURI)))
            }
        }
    }
}
