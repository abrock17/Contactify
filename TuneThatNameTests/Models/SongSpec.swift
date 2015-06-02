import TuneThatName
import Quick
import Nimble

class SongSpec: QuickSpec {
    let arbitraryURI = NSURL(string: "spotify:track:6N2sQ0wEgKMEHdwnYdJuDy")!
    let arbitraryURI2 = NSURL(string: "spotify:track:6N2sQ0wEgKMEHdwnYdJuDZ")!
    
    override func spec() {
        describe("equality") {
            
            it("are not equal when title doesn't match") {
                expect(Song(title: "x", artistName: "artist", uri: self.arbitraryURI))
                    .toNot(equal(Song(title: "y", artistName: "artist2", uri: self.arbitraryURI)))
            }
            
            it("are not equal when uri doesn't match") {
                expect(Song(title: "x", artistName: "artist", uri: self.arbitraryURI))
                    .toNot(equal(Song(title: "x", artistName: "artist2", uri: self.arbitraryURI2)))
            }
            
            it("are equal when title and uri match") {
                expect(Song(title: "x", artistName: "artist", uri: self.arbitraryURI))
                    .to(equal(Song(title: "x", artistName: "artist2", uri: self.arbitraryURI)))
            }
        }
    }
}
