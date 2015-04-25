import TuneThatName
import Foundation
import Quick
import Nimble

class SpotifyServiceSpec: QuickSpec {

    var callbackPlaylist: Playlist?
    var callbackError: NSError?
    
    func playlistCallback(playlistResult: SpotifyService.PlaylistResult) {
        switch (playlistResult) {
        case .Success(let playlist):
            callbackPlaylist = playlist
        case .Failure(let error):
            callbackError = error
        }
    }
    
    override func spec() {
        xdescribe("The Spotify Service") {
            var spotifyService: SpotifyService!

            beforeEach() {
                self.callbackPlaylist = nil
                self.callbackError = nil
                spotifyService = SpotifyService()
            }
            
            describe("retrieve a playlist") {
                
                context("when the playlist exists") {
                    
                    it("calls back with the playlist") {
                        let session = self.getSession()
                        let playlistURI = NSURL(string: "spotify:user:1125623010:playlist:0iNHNVUbb8k9oOPeIiOrT9")
                        spotifyService.retrievePlaylist(playlistURI, session: session, callback: self.playlistCallback)
                        
                        expect(self.callbackPlaylist).toEventuallyNot(beNil(), timeout: 5)
                        expect(self.callbackPlaylist?.uri).to(equal(playlistURI))
                        expect(self.callbackPlaylist?.name).to(equal("Long playlist 5"))
                        expect(self.callbackPlaylist?.songs.count).to(equal(1120))
                        expect(self.callbackPlaylist?.songs.first?.title).to(equal("Happy"))
                        expect(self.callbackPlaylist?.songs.first?.artistName).to(equal("Pharrell Williams"))
                        expect(self.callbackPlaylist?.songs.first?.uri?.absoluteString).to(equal("spotify:track:6NPVjNh8Jhru9xOmyQigds"))
                        expect(self.callbackPlaylist?.songs[809].artistName).to(equal("Madeleine Peyroux, Marc Ribot, Christopher Bruce, Meshell Ndegeocello, Charley Drayton"))
                    }
                }
            }
                
            describe("save a playlist") {
                
                afterEach() {
                    // figure out how to delete playlist
                }

                context("when the playlist is new") {
                    it("creates the new playlist") {
                        let playlist = self.getPlaylist()
                        let session = self.getSession()
                        
                        spotifyService.savePlaylist(playlist, session: session, callback: self.playlistCallback)
                        
                        expect(self.callbackPlaylist).toEventuallyNot(beNil(), timeout: 3)
                        expect(self.callbackPlaylist?.uri).toEventuallyNot(beNil())
                        expect(self.callbackError).to(beNil())
                        
                        if let createdPlaylist = self.callbackPlaylist {
                            
                            var retrievedPlaylist: Playlist?
                            spotifyService.retrievePlaylist(createdPlaylist.uri, session: session) {
                                (playlistResult) in
                                switch (playlistResult) {
                                case .Success(let playlist):
                                    retrievedPlaylist = playlist
                                case .Failure(let error):
                                    println("Error retrieving playlist: \(error)")
                                }
                            }
                            
                            expect(retrievedPlaylist).toEventually(equal(createdPlaylist), timeout: 3)
                        }
                    }
                }
            }
        }
    }
    
    func getSession() -> SPTSession! {
        return SPTSession(
            // fill in these fields to run these tests on demand
            userName: "",
            accessToken: "",
            expirationDate: NSDate(timeIntervalSinceNow: 3600000))
    }
    
    func getPlaylist() -> Playlist! {
        var playlist = Playlist(name: "test playlist")
        for i in 1...75 {
            playlist.songs.append(Song(title: "Susie Q", artistName: "Creedence Clearwater Revival", uri: NSURL(string: "spotify:track:5xpfodSZvstNnuvv0qXg3Y")))
            playlist.songs.append(Song(title: "Suite: Judy Blue Eyes", artistName: "Crosby, Stills & Nash", uri: NSURL(string: "spotify:track:2Jf0PGy9NzR1PTXvRFfaoE")))
        }
        return playlist
    }
}
