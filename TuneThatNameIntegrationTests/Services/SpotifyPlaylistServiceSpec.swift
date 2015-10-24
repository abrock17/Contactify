import TuneThatName
import Quick
import Nimble

class SpotifyPlaylistServiceSpec: QuickSpec {

    var callbackPlaylist: Playlist?
    var callbackError: NSError?
    var callbackForCanceled = false
    
    func playlistCallback(playlistResult: SpotifyPlaylistService.PlaylistResult) {
        switch (playlistResult) {
        case .Success(let playlist):
            callbackPlaylist = playlist
        case .Failure(let error):
            callbackError = error
        case .Canceled:
            callbackForCanceled = true
        }
    }
    
    override func spec() {
        describe("SpotifyPlaylistService") {
            var spotifyPlaylistService: SpotifyPlaylistService!
            
            beforeEach() {
                self.clearCallbackVariables()
                spotifyPlaylistService = SpotifyPlaylistService()
            }
            
            describe("save a playlist") {
                var playlist = self.getPlaylist()
                
                beforeEach() {
                    spotifyPlaylistService.savePlaylist(playlist, callback: self.playlistCallback)
                }
                
                afterEach() {
                    if let playlistURI = self.callbackPlaylist?.uri {
                        spotifyPlaylistService.unfollowPlaylistURI(playlistURI)
                    }
                }

                context("when the playlist is new") {
                    it("creates the new playlist") {
                        expect(self.callbackPlaylist).toEventuallyNot(beNil(), timeout: 10)
                        expect(self.callbackPlaylist?.uri).toNot(beNil())
                        expect(self.callbackPlaylist?.name).to(equal(playlist.name))
                        self.compareSongs(playlist.songs, actualSongs: self.callbackPlaylist!.songs)
                        expect(self.callbackError).to(beNil())
                        
                        if let createdPlaylist = self.callbackPlaylist {
                            self.assertSavedPlaylist(createdPlaylist, canBeRetrievedFromSpotifyPlaylistService: spotifyPlaylistService)
                        }
                    }
                }
                
                context("when the playlist already exists") {
                    var playlistURI: NSURL?
                    beforeEach() {
                        expect(self.callbackPlaylist).toEventuallyNot(beNil(), timeout: 10)
                        expect(self.callbackPlaylist?.uri).toEventuallyNot(beNil())
                        playlist = self.callbackPlaylist
                        playlistURI = self.callbackPlaylist?.uri
                        self.clearCallbackVariables()
                    }

                    it("updates the existing playlist") {
                        if playlistURI != nil {
                            playlist.name = "the new hotttnesss"
                            for _ in 1...37 {
                                playlist.songsWithContacts.append(song: Song(title: "Carrie-Anne", artistName: "The Hollies", uri: NSURL(string: "spotify:track:0EpJ6gnNlNvTVjDuf2OyOY")!), contact: Contact(id: 1, firstName: "Carrie Anne", lastName: "Moss") as Contact?)
                                playlist.songsWithContacts.append(song: Song(title: "Susie Q", artistName: "Creedence Clearwater Revival", uri: NSURL(string: "spotify:track:6z2AyfE9GZxoHqJVSA4NgN")!), contact: Contact(id: 2, firstName: "Susie", lastName: "B Anthony") as Contact?)
                            }
                            for _ in 1...68 {
                                playlist.songsWithContacts.append(song: Song(title: "Billie Jean - Single Version", artistName: "Michael Jackson", uri: NSURL(string: "spotify:track:5ChkMS8OtdzJeqyybCc9R5")!), contact: Contact(id: 3, firstName: "Billie Jean", lastName: "King") as Contact?)
                            }
                            
                            spotifyPlaylistService.savePlaylist(playlist, callback: self.playlistCallback)
                            
                            expect(self.callbackPlaylist).toEventuallyNot(beNil(), timeout: 10)
                            expect(self.callbackPlaylist?.uri).toEventually(equal(playlistURI))
                            expect(self.callbackPlaylist?.name).to(equal(playlist.name))
                            self.compareSongs(playlist.songs, actualSongs: self.callbackPlaylist!.songs)
                            expect(self.callbackError).to(beNil())

                            if let updated = self.callbackPlaylist {
                                self.assertSavedPlaylist(updated, canBeRetrievedFromSpotifyPlaylistService: spotifyPlaylistService)
                            }
                        }
                    }
                }
                
                describe("retrieve a playlist") {
                    
                    context("when the playlist exists") {
                        
                        it("calls back with the playlist") {
                            let playlistURI = NSURL(string: "spotify:user:1125623010:playlist:0iNHNVUbb8k9oOPeIiOrT9")
                            
                            spotifyPlaylistService.retrievePlaylist(playlistURI, callback: self.playlistCallback)
                            
                            expect(self.callbackPlaylist).toEventuallyNot(beNil(), timeout: 10)
                            expect(self.callbackPlaylist?.uri).toEventually(equal(playlistURI), timeout: 10)
                            expect(self.callbackPlaylist?.name).to(equal("Long playlist 5"))
                            expect(self.callbackPlaylist?.songs.count).to(equal(1120))
                            expect(self.callbackPlaylist?.songs.first?.title).to(equal("Happy"))
                            expect(self.callbackPlaylist?.songs.first?.displayArtistName).to(equal("Pharrell Williams"))
                            expect(self.callbackPlaylist?.songs.first?.uri.absoluteString).to(equal("spotify:track:6NPVjNh8Jhru9xOmyQigds"))
                            if self.callbackPlaylist?.songs.count > 809 {
                                expect(self.callbackPlaylist?.songs[809].displayArtistName).to(equal("Madeleine Peyroux, Marc Ribot, Christopher Bruce, Meshell Ndegeocello and Charley Drayton"))
                            }
                        }
                        
                        afterEach() {
                            self.clearCallbackVariables()
                        }
                    }
                }
            }
        }
    }
    
    func getPlaylist() -> Playlist! {
        var songsWithContacts: [(song: Song, contact: Contact?)] = []
        for _ in 1...75 {
            songsWithContacts.append(song: Song(title: "Susie Q", artistName: "Creedence Clearwater Revival", uri: NSURL(string: "spotify:track:6z2AyfE9GZxoHqJVSA4NgN")!), contact: Contact(id: 1, firstName: "Susie", lastName: "Q") as Contact?)
            songsWithContacts.append(song: Song(title: "Suite: Judy Blue Eyes", artistName: "Crosby, Stills & Nash", uri: NSURL(string: "spotify:track:2Jf0PGy9NzR1PTXvRFfaoE")!), contact: Contact(id: 2, firstName: "Judie", lastName: "Blume") as Contact?)
        }
        return Playlist(name: "test playlist", songsWithContacts: songsWithContacts)
    }
    
    func clearCallbackVariables() {
        callbackPlaylist = nil
        callbackError = nil
        callbackForCanceled = false
    }
    
    func assertSavedPlaylist(savedPlaylist: Playlist, canBeRetrievedFromSpotifyPlaylistService spotifyPlaylistService: SpotifyPlaylistService) {
        var retrievedPlaylist: Playlist?
        waitUntil(timeout: 4) { done in
            spotifyPlaylistService.retrievePlaylist(savedPlaylist.uri) {
                (playlistResult) in
                switch (playlistResult) {
                case .Success(let playlist):
                    retrievedPlaylist = playlist
                case .Failure(let error):
                    print("Error retrieving playlist: \(error)")
                case .Canceled:
                    print("Playlist retrieval was canceled")
                }
            }
            NSThread.sleepForTimeInterval(3)
            done()
        }
        
        expect(retrievedPlaylist).toEventually(equal(savedPlaylist), timeout: 3)
    }
    
    func compareSongs(expectedSongs: [Song], actualSongs: [Song]) {
        for (index, expectedSong) in expectedSongs.enumerate() {
            let actualSong = actualSongs[index]
            expect(actualSong.title).to(equal(expectedSong.title))
            expect(actualSong.displayArtistName).to(equal(expectedSong.displayArtistName))
            expect(actualSong.uri).to(equal(expectedSong.uri))
        }
    }
}