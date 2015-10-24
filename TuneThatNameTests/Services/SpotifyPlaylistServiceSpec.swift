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
            var mockSpotifyAuthService: MockSpotifyAuthService!
            
            let playlist = Playlist(name: "A list of songs that I would like saved in this order", uri: nil, songsWithContacts: [(song: Song(title: "Kate", artistName: "Ben Folds Five", uri: NSURL(string: "spotify:track:03yyEqyianASgmrdIYwOhd")!), contact: nil)])
            
            beforeEach() {
                self.callbackPlaylist = nil
                self.callbackError = nil
                self.callbackForCanceled = false
                
                mockSpotifyAuthService = MockSpotifyAuthService()
                spotifyPlaylistService = SpotifyPlaylistService(spotifyAuthService: mockSpotifyAuthService)
            }
            
            describe("save a playlist") {
                context("when the auth service calls back with an error") {
                    let error = NSError(domain: "com.spotify.ios", code: 9876, userInfo: [NSLocalizedDescriptionKey: "error logging in"])
                    
                    it("calls back with the error") {
                        mockSpotifyAuthService.mocker.prepareForCallTo(MockSpotifyAuthService.Method.doWithSession, returnValue: SpotifyAuthService.AuthResult.Failure(error))
                        
                        spotifyPlaylistService.savePlaylist(playlist, callback: self.playlistCallback)
                        
                        expect(self.callbackError).to(equal(error))
                        expect(self.callbackPlaylist).to(beNil())
                        expect(self.callbackForCanceled).to(beFalse())
                    }
                }
                
                context("when the auth service calls back with canceled") {
                    it("calls back with no error") {
                        mockSpotifyAuthService.mocker.prepareForCallTo(MockSpotifyAuthService.Method.doWithSession, returnValue: SpotifyAuthService.AuthResult.Canceled)
                        
                        spotifyPlaylistService.savePlaylist(playlist, callback: self.playlistCallback)
                        
                        expect(self.callbackForCanceled).to(beTrue())
                        expect(self.callbackError).to(beNil())
                        expect(self.callbackPlaylist).to(beNil())
                    }
                }
            }
        }
    }
}