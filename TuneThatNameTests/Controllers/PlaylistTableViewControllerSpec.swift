import TuneThatName
import Foundation
import Quick
import Nimble

let savePlaylistMethod = "savePlaylist"
let findSongMethod = "findSong"

class PlaylistTableViewControllerSpec: QuickSpec {
    
    override func spec() {
        
        describe("PlaylistTableViewController") {
            var playlistTableViewController: PlaylistTableViewController!
//            var mockEchoNestService: MockEchoNestService!
            var mockSpotifyService: MockSpotifyService!
            
            beforeEach() {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                playlistTableViewController = storyboard.instantiateViewControllerWithIdentifier("PlaylistTableViewController") as  PlaylistTableViewController

                mockSpotifyService = MockSpotifyService()
                playlistTableViewController.spotifyService = mockSpotifyService
//                mockEchoNestService = MockEchoNestService()
//                playlistTableViewController.echoNestService = mockEchoNestService
                
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
                    let spotifyAuth = self.getFakeSpotifyAuth(expiresIn: 60)
                    let playlistToBeSaved = Playlist(name: "playlist to be saved")

                    beforeEach() {
                        playlistTableViewController.spotifyAuth = spotifyAuth
                        playlistTableViewController.playlist = playlistToBeSaved
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
                    
                    context("upon saving the playlist successfully") {
                        let savedPlaylist = Playlist(name: "saved playlist", uri: NSURL(string: "uri"))
                        beforeEach() {
                            mockSpotifyService.mocker.prepareForCallTo(savePlaylistMethod, returnValue: SpotifyService.PlaylistResult.Success(savedPlaylist))
                            
                            self.pressSaveButton(playlistTableViewController)
                        }
                        
                        it("has the saved playlist") {
                            expect(playlistTableViewController.playlist).toEventually(equal(savedPlaylist))
                        }
                        
                        it("updates the save button text") {
                            expect(playlistTableViewController.saveButton.title).toEventually(equal("Playlist Saved"))
                        }

                        it("disables the save button") {
                            let enabled = playlistTableViewController.saveButton.enabled
                            expect(playlistTableViewController.saveButton.enabled).toEventuallyNot(beTrue())
                        }
                    }
                    
                    context("upon failing to save the playlist") {
                        let error = NSError(domain: "com.spotify.ios", code: 777, userInfo: [NSLocalizedDescriptionKey: "error description"])
                        
                        it("displays the error message in an alert") {
                            mockSpotifyService.mocker.prepareForCallTo(savePlaylistMethod, returnValue: SpotifyService.PlaylistResult.Failure(error))
                            
                            self.pressSaveButton(playlistTableViewController)

                            expect(playlistTableViewController.presentedViewController).toEventuallyNot(beNil())
                            expect(playlistTableViewController.presentedViewController).toEventually(beAnInstanceOf(UIAlertController))
                            let alertController = playlistTableViewController.presentedViewController as UIAlertController
                            expect(alertController.title).toEventually(equal("Unable to Save Your Playlist"))
                            expect(alertController.message).toEventually(equal(error.userInfo![NSLocalizedDescriptionKey] as String?))
                        }
                    }
                }
            }
            
            describe("successful login") {
                let playlistToBeSaved = Playlist(name: "playlist to be saved")
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

//class MockEchoNestService: EchoNestService {
//    
//
//    let mocker = Mocker()
//    
//    override func findSong(#titleSearchTerm: String!, callback: (EchoNestService.SongResult) -> Void) {
//        mocker.recordCall(findSongMethod, parameters: titleSearchTerm)
//        let mockedResult = mocker.returnValueForCallTo(findSongMethod)
//        if let mockedResult = mockedResult as? EchoNestService.SongResult {
//            callback(mockedResult)
//        } else {
//            callback(.Success(Song(title: "unimportant mocked title", artistName: nil, uri: nil)))
//        }
//    }
//}

class MockSpotifyService: SpotifyService {
    
    let mocker = Mocker()
    
    override func savePlaylist(playlist: Playlist!, session: SPTSession!, callback: (SpotifyService.PlaylistResult) -> Void) {
        mocker.recordCall(savePlaylistMethod, parameters: playlist, session)
        let mockedResult = mocker.returnValueForCallTo(savePlaylistMethod)
        if let mockedResult = mockedResult as? SpotifyService.PlaylistResult {
            callback(mockedResult)
        } else {
            callback(.Success(Playlist(name: "unimportant mocked playlist")))
        }
    }
}
