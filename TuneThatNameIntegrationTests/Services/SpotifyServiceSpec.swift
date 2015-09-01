import TuneThatName
import Quick
import Nimble

class SpotifyServiceSpec: QuickSpec {

    var callbackPlaylist: Playlist?
    var callbackError: NSError?
    var session: SPTSession!
    
    func playlistCallback(playlistResult: SpotifyService.PlaylistResult) {
        switch (playlistResult) {
        case .Success(let playlist):
            callbackPlaylist = playlist
        case .Failure(let error):
            callbackError = error
        }
    }
    
    override func spec() {
        describe("SpotifyService") {
            var spotifyService: SpotifyService!
            
            beforeSuite() {
                SpotifyService.initializeDefaultSPTAuth()
                self.session = self.getSession()
            }

            beforeEach() {
                self.clearCallbackVariables()
                spotifyService = SpotifyService()
            }
            
            describe("save a playlist") {
                var playlist = self.getPlaylist()
                
                beforeEach() {
                    spotifyService.savePlaylist(playlist, session: self.session, callback: self.playlistCallback)
                }
                
                afterEach() {
                    if let playlistURI = self.callbackPlaylist?.uri {
                        spotifyService.unfollowPlaylistURI(playlistURI, inSession: self.session)
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
                            self.assertSavedPlaylist(createdPlaylist, canBeRetrievedFromSpotifyService: spotifyService)
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
                            for i in 1...37 {
                                playlist.songsWithContacts.append(song: Song(title: "Carrie-Anne", artistName: "The Hollies", uri: NSURL(string: "spotify:track:0EpJ6gnNlNvTVjDuf2OyOY")!), contact: Contact(id: 1, firstName: "Carrie Anne", lastName: "Moss") as Contact?)
                                playlist.songsWithContacts.append(song: Song(title: "Susie Q", artistName: "Creedence Clearwater Revival", uri: NSURL(string: "spotify:track:6z2AyfE9GZxoHqJVSA4NgN")!), contact: Contact(id: 2, firstName: "Susie", lastName: "B Anthony") as Contact?)
                            }
                            for i in 1...68 {
                                playlist.songsWithContacts.append(song: Song(title: "Billie Jean - Single Version", artistName: "Michael Jackson", uri: NSURL(string: "spotify:track:5ChkMS8OtdzJeqyybCc9R5")!), contact: Contact(id: 3, firstName: "Billie Jean", lastName: "King") as Contact?)
                            }
                            
                            spotifyService.savePlaylist(playlist, session: self.session, callback: self.playlistCallback)
                            
                            expect(self.callbackPlaylist).toEventuallyNot(beNil(), timeout: 10)
                            expect(self.callbackPlaylist?.uri).toEventually(equal(playlistURI))
                            expect(self.callbackPlaylist?.name).to(equal(playlist.name))
                            self.compareSongs(playlist.songs, actualSongs: self.callbackPlaylist!.songs)
                            expect(self.callbackError).to(beNil())

                            if let updated = self.callbackPlaylist {
                                self.assertSavedPlaylist(updated, canBeRetrievedFromSpotifyService: spotifyService)
                            }
                        }
                    }
                }
                
                describe("retrieve a playlist") {
                    
                    context("when the playlist exists") {
                        
                        it("calls back with the playlist") {
                            let playlistURI = NSURL(string: "spotify:user:1125623010:playlist:0iNHNVUbb8k9oOPeIiOrT9")
                            
                            spotifyService.retrievePlaylist(playlistURI, session: self.session, callback: self.playlistCallback)
                            
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
    
    func getSession() -> SPTSession! {
        return SPTSession(
            // fill in these fields to run these tests on demand
            userName: "abrock17",
            accessToken: "BQDp-Ud2_UMnpmYOQcxQjUuz8unC3Z0MohvjGtBEFEtP4y7rWayI48f8eHMLb5NlaFiPnmfVBvg2c78YiXjbTuVdhzO3l6c5Uy3jai_zauhKJjZ5TPMWxBZWbDpm3VZOsKscsmMGQ_78Sr_Ea4ieQOgTXedPkuTisYyqOhjfgaB7KNCscT31sPy_p6nzHkcqbEcvekh6YidTVWlSl_rovhuZsTs8ght4eCaK7WIhkQ",
            expirationDate: NSDate(timeIntervalSinceNow: 3600000))
    }
    
    func getPlaylist() -> Playlist! {
        var songsWithContacts: [(song: Song, contact: Contact?)] = []
        for i in 1...75 {
            songsWithContacts.append(song: Song(title: "Susie Q", artistName: "Creedence Clearwater Revival", uri: NSURL(string: "spotify:track:6z2AyfE9GZxoHqJVSA4NgN")!), contact: Contact(id: 1, firstName: "Susie", lastName: "Q") as Contact?)
            songsWithContacts.append(song: Song(title: "Suite: Judy Blue Eyes", artistName: "Crosby, Stills & Nash", uri: NSURL(string: "spotify:track:2Jf0PGy9NzR1PTXvRFfaoE")!), contact: Contact(id: 2, firstName: "Judie", lastName: "Blume") as Contact?)
        }
        return Playlist(name: "test playlist", songsWithContacts: songsWithContacts)
    }
    
    func clearCallbackVariables() {
        callbackPlaylist = nil
        callbackError = nil
    }
    
    func assertSavedPlaylist(savedPlaylist: Playlist, canBeRetrievedFromSpotifyService spotifyService: SpotifyService) {
        var retrievedPlaylist: Playlist?
        waitUntil(timeout: 4) { done in
            spotifyService.retrievePlaylist(savedPlaylist.uri, session: self.session) {
                (playlistResult) in
                switch (playlistResult) {
                case .Success(let playlist):
                    retrievedPlaylist = playlist
                case .Failure(let error):
                    println("Error retrieving playlist: \(error)")
                }
            }
            NSThread.sleepForTimeInterval(3)
            done()
        }
        
        expect(retrievedPlaylist).toEventually(equal(savedPlaylist), timeout: 3)
    }
    
    func compareSongs(expectedSongs: [Song], actualSongs: [Song]) {
        for (index, expectedSong) in enumerate(expectedSongs) {
            let actualSong = actualSongs[index]
            expect(actualSong.title).to(equal(expectedSong.title))
            expect(actualSong.displayArtistName).to(equal(expectedSong.displayArtistName))
            expect(actualSong.uri).to(equal(expectedSong.uri))
        }
    }
}