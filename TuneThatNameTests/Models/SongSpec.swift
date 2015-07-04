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
        
        describe("display artist name") {
            it("has the expected format for one artist") {
                expect(Song(title: "x", artistNames: ["artist"], uri: self.arbitraryURI).displayArtistName).to(equal("artist"))
            }
            
            it("has the expected format for two artists") {
                expect(Song(title: "x", artistNames: ["artist", "artist 2"], uri: self.arbitraryURI).displayArtistName).to(equal("artist and artist 2"))
            }

            it("has the expected format for three artists") {
                expect(Song(title: "x", artistNames: ["artist", "artist 2", "artist 3"], uri: self.arbitraryURI).displayArtistName).to(equal("artist, artist 2 and artist 3"))
            }
        }
    }
}
