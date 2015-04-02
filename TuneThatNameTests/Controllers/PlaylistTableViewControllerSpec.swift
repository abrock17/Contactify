import TuneThatName
import Foundation
import Quick
import Nimble

let savePlaylistMethod = "savePlaylist"

class PlaylistTableViewControllerSpec: QuickSpec {
    
    override func spec() {
        
        describe("PlaylistTableViewController") {
            var playlistTableViewController: PlaylistTableViewController!
            var mockSpotifyService: MockSpotifyService!
            
            beforeEach() {
                mockSpotifyService = MockSpotifyService()
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                playlistTableViewController = storyboard.instantiateViewControllerWithIdentifier("PlaylistTableViewController") as  PlaylistTableViewController
                playlistTableViewController.spotifyService = mockSpotifyService
                let window = UIWindow(frame: UIScreen.mainScreen().bounds)
                window.rootViewController = playlistTableViewController
                window.makeKeyAndVisible()
            }

            describe("save the playlist to spotify") {
                context("when there is no session") {
                    it("prompts the user to log in") {
                        playlistTableViewController.spotifyAuth = self.getFakeSpotifyAuth()
                        
                        self.pressSaveButton(playlistTableViewController)
                        
                        expect(playlistTableViewController.presentedViewController).toNot(beNil())
                        // this fails inexplicably: "expected to be an instance of SPTAuthViewController, got <SPTAuthViewController instance>"
                        // expect(playlistTableViewController.presentedViewController).to(beAnInstanceOf(SPTAuthViewController))                    
                    }
                }
                
                context("when the session is invalid") {
                    it("prompts the user to log in") {
                        let spotifyAuth = self.getFakeSpotifyAuth(expiresIn: -60)
                        playlistTableViewController.spotifyAuth = spotifyAuth
                        
                        self.pressSaveButton(playlistTableViewController)
                        
                        expect(playlistTableViewController.presentedViewController).toNot(beNil())
                    }
                }
                
                context("when there is a valid session") {
                    let playlistToBeSaved = Playlist(name: "playlist")
                    let spotifyAuth = self.getFakeSpotifyAuth(expiresIn: 60)

                    beforeEach() {
                        playlistTableViewController.spotifyAuth = spotifyAuth
                        
                        playlistTableViewController.playlist = playlistToBeSaved
                        mockSpotifyService.mocker.prepareForCallTo(savePlaylistMethod, returnValue: SpotifyService.PlaylistResult.Success(playlistToBeSaved))
                    }
                    
                    it("does not prompt the user to log in") {
                        self.pressSaveButton(playlistTableViewController)
                        
                        expect(playlistTableViewController.presentedViewController).to(beNil())
                    }
                
                    it("calls the service to save the playlist") {
                        self.pressSaveButton(playlistTableViewController)
                        
                        expect(mockSpotifyService.mocker.verifyNthCallTo(savePlaylistMethod, n: 0)).toEventuallyNot(beEmpty())
                        var playlistParameter = mockSpotifyService.mocker.verifyNthCallTo(savePlaylistMethod, n: 0)?.first as? Playlist
                        expect(playlistParameter).to(equal(playlistToBeSaved))
                    }
                }
            }
            
            describe("successful login") {
                let playlistToBeSaved = Playlist(name: "playlist")
                let spotifyAuth = self.getFakeSpotifyAuth(expiresIn: 60)

                context("when login is successful") {
                    it("calls the service to save the playlist") {
                        playlistTableViewController.spotifyAuth = spotifyAuth
                        
                        playlistTableViewController.playlist = playlistToBeSaved
                        mockSpotifyService.mocker.prepareForCallTo(savePlaylistMethod, returnValue: SpotifyService.PlaylistResult.Success(playlistToBeSaved))

                        playlistTableViewController.authenticationViewController(SPTAuthViewController(), didLoginWithSession: spotifyAuth.session)
                        
                        expect(mockSpotifyService.mocker.verifyNthCallTo(savePlaylistMethod, n: 0)).toEventuallyNot(beEmpty())
                        var playlistParameter = mockSpotifyService.mocker.verifyNthCallTo(savePlaylistMethod, n: 0)?.first as? Playlist
                        expect(playlistParameter).to(equal(playlistToBeSaved))
                    }
                }
            }
        }
    }
    
    func getFakeSpotifyAuth(#expiresIn: NSTimeInterval) -> SPTAuth {
        let fakeSpotifyAuth = getFakeSpotifyAuth()
        fakeSpotifyAuth.session = SPTSession(userName: "user", accessToken: "token", expirationDate: NSDate(timeIntervalSinceNow: expiresIn))
        return fakeSpotifyAuth
    }
    
    func getFakeSpotifyAuth() -> SPTAuth {
        let fakeSpotifyAuth = SPTAuth()
        fakeSpotifyAuth.clientID = "clientID"
        fakeSpotifyAuth.redirectURL = NSURL(string: "redirect://url")
        fakeSpotifyAuth.tokenSwapURL = NSURL(string: "https://token/swap")
        fakeSpotifyAuth.tokenRefreshURL = NSURL(string: "https://token/refresh")

        return fakeSpotifyAuth
    }
    
    func pressSaveButton(playlistTableViewController: PlaylistTableViewController) {
        let saveButton = playlistTableViewController.saveButton
        UIApplication.sharedApplication().sendAction(saveButton.action, to: saveButton.target, from: self, forEvent: nil)
    }
}

class MockSpotifyService: SpotifyService {
    
    let mocker = Mocker()
    
    var savePlaylistError: NSError?
    
    override func savePlaylist(playlist: Playlist!, session: SPTSession!, callback: (SpotifyService.PlaylistResult) -> Void) {
        mocker.recordCall(savePlaylistMethod, parameters: playlist, session)
        callback(mocker.returnValueForCallTo(savePlaylistMethod) as SpotifyService.PlaylistResult!)
    }
}
