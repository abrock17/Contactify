import TuneThatName
import Foundation
import Quick
import Nimble

class PlaylistSpec: QuickSpec {
    let arbitraryURI = NSURL(string: "spotify:user:1223787057:playlist:0GNgc2cNhDjTWPPPcbaHuk")!
    let songWithContact1 = (song: Song(title: "Susie Q", artistName: "Creedence Clearwater Revival", uri: NSURL(string: "spotify:track:6N2sQ0wEgKMEHdwnYdJuDy")!), contact: Contact(id: 1, firstName: "Susie", lastName: "Q") as Contact?)
    let songWithContact2 = (song: Song(title: "Wake up Little Susie", artistName: "The Everly Brothers", uri: NSURL(string: "spotify:track:5EmUVcFfB9FnJAeOoz1DfX")!), contact: Contact(id: 1, firstName: "Susie", lastName: "Q") as Contact?)
    let songWithContact3 = (song: Song(title: "Susie Q", artistName: "Creedence Clearwater Revival", uri: NSURL(string: "spotify:track:6N2sQ0wEgKMEHdwnYdJuDy")!), contact: Contact(id: 2, firstName: "Susie", lastName: "R") as Contact?)
    
    override func spec() {
        describe("Playlist") {
            describe("equality") {
                
                it("is not when name doesn't match") {
                    expect(Playlist(name: "x", uri: self.arbitraryURI, songsWithContacts: [self.songWithContact1]))
                        .toNot(equal(Playlist(name: "y", uri: self.arbitraryURI, songsWithContacts: [self.songWithContact1])))
                }
                
                it("is not when uri doesn't match") {
                    expect(Playlist(name: "x", uri: self.arbitraryURI, songsWithContacts: [self.songWithContact1]))
                        .toNot(equal(Playlist(name: "y", songsWithContacts: [self.songWithContact1])))
                }
                
                it ("is not when songs don't match") {
                    expect(Playlist(name: "x", uri: self.arbitraryURI,
                        songsWithContacts: [self.songWithContact1]))
                        .toNot(equal(Playlist(name: "x", uri: self.arbitraryURI,
                            songsWithContacts: [])))
                    expect(Playlist(name: "x", uri: self.arbitraryURI,
                        songsWithContacts: [self.songWithContact1, self.songWithContact2]))
                        .toNot(equal(Playlist(name: "x", uri: self.arbitraryURI,
                            songsWithContacts: [self.songWithContact1, self.songWithContact3])))
                    expect(Playlist(name: "x", uri: self.arbitraryURI,
                        songsWithContacts: [self.songWithContact2, self.songWithContact3]))
                        .toNot(equal(Playlist(name: "x", uri: self.arbitraryURI,
                            songsWithContacts: [self.songWithContact3, self.songWithContact2])))
                }
                
                it ("is when name, uri, and songs match") {
                    expect(Playlist(name: "x", uri: self.arbitraryURI,
                        songsWithContacts: [self.songWithContact1, self.songWithContact3]))
                        .to(equal(Playlist(name: "x", uri: self.arbitraryURI,
                            songsWithContacts: [self.songWithContact3, self.songWithContact1])))
                }
            }
            
            describe("songs") {
                var playlist = Playlist(name: "x", uri: self.arbitraryURI,
                    songsWithContacts: [self.songWithContact1, self.songWithContact2, self.songWithContact3])
                it("returns an array of URIs corresponding to the songs") {
                    expect(playlist.songs)
                        .to(equal([self.songWithContact1.song, self.songWithContact2.song, self.songWithContact3.song]))
                }
            }
            
            describe("song URIs") {
                var playlist = Playlist(name: "x", uri: self.arbitraryURI,
                    songsWithContacts: [self.songWithContact1, self.songWithContact2, self.songWithContact3])
                it("returns an array of URIs corresponding to the songs") {
                    expect(playlist.songURIs)
                        .to(equal([self.songWithContact1.song.uri, self.songWithContact2.song.uri, self.songWithContact3.song.uri]))
                }
            }
        }
    }
}
