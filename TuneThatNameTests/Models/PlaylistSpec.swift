import TuneThatName
import Foundation
import Quick
import Nimble

class PlaylistSpec: QuickSpec {
    let arbitraryURI = NSURL(string: "spotify:user:1223787057:playlist:0GNgc2cNhDjTWPPPcbaHuk")
    let arbitrarySong = Song(title: "Susie Q", artistName: "Creedence Clearwater Revival", uri: NSURL(string: "spotify:track:6N2sQ0wEgKMEHdwnYdJuDy")!)
    let arbitrarySong2 = Song(title: "Angie", artistName: "The Rolling Stones", uri: NSURL(string: "spotify:track:15aG4oK5KbxKTuCSqZI5Qb")!)
    
    override func spec() {
        describe("Playlist") {
            describe("equality") {
                
                it("is not when name doesn't match") {
                    expect(Playlist(name: "x")).toNot(equal(Playlist(name: "y")))
                }
                
                it("is not when uri doesn't match") {
                    expect(Playlist(name: "x", uri: self.arbitraryURI)).toNot(equal(Playlist(name: "x")))
                }
                
                it ("is not when songs don't match") {
                    expect(Playlist(name: "x", uri: self.arbitraryURI, songs: [self.arbitrarySong])).toNot(equal(Playlist(name: "x", uri: self.arbitraryURI)))
                }
                
                it ("is when name, uri, and songs match") {
                    expect(Playlist(name: "x", uri: self.arbitraryURI, songs: [self.arbitrarySong])).to(equal(Playlist(name: "x", uri: self.arbitraryURI, songs: [self.arbitrarySong])))
                }
            }
            
            describe("song URIs") {
                var playlist = Playlist(name: "x", uri: self.arbitraryURI, songs: [self.arbitrarySong, self.arbitrarySong2])
                it("returns an array of URIs corresponding to the songs") {
                    expect(playlist.songURIs).to(equal([self.arbitrarySong.uri, self.arbitrarySong2.uri]))
                }
            }
        }
    }
}
