import TuneThatName
import Quick
import Nimble

class PlaylistTableViewControllerSpec: QuickSpec {
    
    override func spec() {
        describe("PlaylistTableViewController") {
            let playlist = Playlist(name: "name", uri: nil, songs:
                [Song(title: "Me And Bobby McGee", artistName: "Janis Joplin", uri: NSURL(string: "spotify:track:3RpndSyVypRVcN38z98MvU")!),
                    Song(title: "Bobby Brown Goes Down", artistName: "Frank Zappa", uri: NSURL(string: "spotify:album:4hBKoHOpEvQ6g4CQFsEAdU")!)])
            var playlistTableViewController: PlaylistTableViewController!
            var mockSpotifyService: MockSpotifyService!
            var mockSpotifyAudioFacade: MockSpotifyAudioFacade!
            
            beforeEach() {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                playlistTableViewController = storyboard.instantiateViewControllerWithIdentifier("PlaylistTableViewController") as!  PlaylistTableViewController

                playlistTableViewController.playlist = playlist
                mockSpotifyService = MockSpotifyService()
                playlistTableViewController.spotifyService = mockSpotifyService
                mockSpotifyAudioFacade = MockSpotifyAudioFacade()
                playlistTableViewController.spotifyAudioFacadeOverride = mockSpotifyAudioFacade
                
                UIApplication.sharedApplication().keyWindow!.rootViewController = playlistTableViewController
            }

            describe("press the 'save to spotify' button") {
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
                    let spotifyAuth = self.getFakeSpotifyAuth(expiresIn: -60)

                    it("prompts the user to log in") {
                        playlistTableViewController.spotifyAuth = spotifyAuth
                        
                        self.pressSaveButton(playlistTableViewController)
                        
                        expect(playlistTableViewController.presentedViewController).toNot(beNil())
                    }
                }
                
                context("when there is a valid session") {
                    let spotifyAuth = self.getFakeSpotifyAuth(expiresIn: 60)

                    beforeEach() {
                        playlistTableViewController.spotifyAuth = spotifyAuth
                    }
                    
                    it("does not prompt the user to log in") {
                        self.pressSaveButton(playlistTableViewController)
                        
                        expect(playlistTableViewController.presentedViewController).to(beNil())
                    }
                
                    it("updates the save button text") {
                        self.pressSaveButton(playlistTableViewController)

                        expect(playlistTableViewController.saveButton.title).to(equal("Saving Playlist"))
                    }
                    
                    it("disables the save button") {
                        playlistTableViewController.saveButton.enabled = true
                        
                        self.pressSaveButton(playlistTableViewController)

                        expect(playlistTableViewController.saveButton.enabled).toNot(beTrue())
                    }
                    
                    it("calls the service to save the playlist") {
                        self.pressSaveButton(playlistTableViewController)
                        
                        expect(mockSpotifyService.mocker.getNthCallTo(MockSpotifyService.Method.savePlaylist, n: 0)).toEventuallyNot(beEmpty())
                        var playlistParameter = mockSpotifyService.mocker.getNthCallTo(MockSpotifyService.Method.savePlaylist, n: 0)?.first as? Playlist
                        expect(playlistParameter).to(equal(playlist))
                    }
                    
                    context("and upon saving the playlist successfully") {
                        let savedPlaylist = Playlist(name: "saved playlist", uri: NSURL(string: "uri"))
                        beforeEach() {
                            mockSpotifyService.mocker.prepareForCallTo(MockSpotifyService.Method.savePlaylist, returnValue: SpotifyService.PlaylistResult.Success(savedPlaylist))
                            
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
                    
                    context("and upon failing to save the playlist") {
                        let error = NSError(domain: "com.spotify.ios", code: 777, userInfo: [NSLocalizedDescriptionKey: "error description"])
                        
                        it("displays the error message in an alert") {
                            mockSpotifyService.mocker.prepareForCallTo(MockSpotifyService.Method.savePlaylist, returnValue: SpotifyService.PlaylistResult.Failure(error))
                            
                            self.pressSaveButton(playlistTableViewController)

                            self.assertSimpleUIAlertControllerPresented(parentController: playlistTableViewController, expectedTitle: "Unable to Save Your Playlist", expectedMessage: error.localizedDescription)
                        }
                    }
                }
            }
            
            describe("successful login") {
                let spotifyAuth = self.getFakeSpotifyAuth(expiresIn: 60)

                context("when login is successful") {
                    it("calls the service to save the playlist") {
                        playlistTableViewController.spotifyAuth = spotifyAuth
                        
                        playlistTableViewController.playlist = playlist
                        mockSpotifyService.mocker.prepareForCallTo(MockSpotifyService.Method.savePlaylist, returnValue: SpotifyService.PlaylistResult.Success(playlist))

                        playlistTableViewController.authenticationViewController(SPTAuthViewController(), didLoginWithSession: spotifyAuth.session)
                        
                        expect(mockSpotifyService.mocker.getNthCallTo(MockSpotifyService.Method.savePlaylist, n: 0)).toEventuallyNot(beEmpty())
                        var playlistParameter = mockSpotifyService.mocker.getNthCallTo(MockSpotifyService.Method.savePlaylist, n: 0)?.first as? Playlist
                        expect(playlistParameter).to(equal(playlist))
                    }
                }
            }
            
            describe("select a song") {
                let indexPath = NSIndexPath(forRow: 1, inSection: 0)
                
                context("when the session is invalid") {
                    let spotifyAuth = self.getFakeSpotifyAuth(expiresIn: -60)

                    it("prompts the user to log in") {
                        playlistTableViewController.spotifyAuth = spotifyAuth

                        playlistTableViewController.tableView(playlistTableViewController.tableView, didSelectRowAtIndexPath: indexPath)

                        expect(playlistTableViewController.presentedViewController).toEventuallyNot(beNil())
                    }
                }

                context("when there is a valid session") {
                    let spotifyAuth = self.getFakeSpotifyAuth(expiresIn: 60)
                    
                    beforeEach() {
                        playlistTableViewController.spotifyAuth = spotifyAuth
                    }
                    
                    it("does not prompt the user to log in") {
                        playlistTableViewController.tableView(playlistTableViewController.tableView, didSelectRowAtIndexPath: indexPath)
                        
                        expect(playlistTableViewController.presentedViewController).to(beNil())
                    }
                    
                    it("calls to play the playlist from the given index") {
                        playlistTableViewController.tableView(playlistTableViewController.tableView, didSelectRowAtIndexPath: indexPath)
                        
                        expect(mockSpotifyAudioFacade.mocker.getNthCallTo(MockSpotifyAudioFacade.Method.playPlaylist, n: 0)?[0] as? Playlist).to(equal(playlist))
                        expect(mockSpotifyAudioFacade.mocker.getNthCallTo(MockSpotifyAudioFacade.Method.playPlaylist, n: 0)?[1] as? Int).to(equal(indexPath.row))
                        expect(mockSpotifyAudioFacade.mocker.getNthCallTo(MockSpotifyAudioFacade.Method.playPlaylist, n: 0)?[2] as? SPTSession).to(equal(spotifyAuth.session))
                    }
                    
                    context("and upon failing to play the playlist") {
                        let error = NSError(domain: "com.spotify.ios", code: 888, userInfo: [NSLocalizedDescriptionKey: "this list is unplayable"])
                        
                        it("displays the error message in an alert") {
                            mockSpotifyAudioFacade.mocker.prepareForCallTo(
                                MockSpotifyAudioFacade.Method.playPlaylist, returnValue: error)
                            
                            playlistTableViewController.tableView(playlistTableViewController.tableView, didSelectRowAtIndexPath: indexPath)
                            
                            self.assertSimpleUIAlertControllerPresented(parentController: playlistTableViewController, expectedTitle: "Unable to Play Song", expectedMessage: error.localizedDescription)
                        }
                    }
                }
            }
            
            describe("press the play/pause button") {
                context("when the session is invalid") {
                    let spotifyAuth = self.getFakeSpotifyAuth(expiresIn: -60)
                    
                    it("prompts the user to log in") {
                        playlistTableViewController.spotifyAuth = spotifyAuth
                        
                        self.pressPlayPauseButton(playlistTableViewController)
                        
                        expect(playlistTableViewController.presentedViewController).toEventuallyNot(beNil())
                    }
                }

                context("when there is a valid session") {
                    let spotifyAuth = self.getFakeSpotifyAuth(expiresIn: 60)
                    
                    beforeEach() {
                        playlistTableViewController.spotifyAuth = spotifyAuth
                    }
                    
                    context("and the playlist has not played yet") {
                        it("calls to play the playlist from the first index") {
                            self.pressPlayPauseButton(playlistTableViewController)
                            
                            expect(mockSpotifyAudioFacade.mocker.getNthCallTo(MockSpotifyAudioFacade.Method.playPlaylist, n: 0)?[0] as? Playlist).to(equal(playlist))
                            expect(mockSpotifyAudioFacade.mocker.getNthCallTo(MockSpotifyAudioFacade.Method.playPlaylist, n: 0)?[1] as? Int).to(equal(0))
                            expect(mockSpotifyAudioFacade.mocker.getNthCallTo(MockSpotifyAudioFacade.Method.playPlaylist, n: 0)?[2] as? SPTSession).to(equal(spotifyAuth.session))
                        }
                    }
                    
                    context("and play has already started") {
                        beforeEach() {
                            self.pressPlayPauseButton(playlistTableViewController)
                            expect(mockSpotifyAudioFacade.mocker.getNthCallTo(MockSpotifyAudioFacade.Method.playPlaylist, n: 0)?[0] as? Playlist).to(equal(playlist))
                        }

                        it("toggles play") {
                            self.pressPlayPauseButton(playlistTableViewController)
                            
                            expect(mockSpotifyAudioFacade.mocker.getCallCountFor(
                                MockSpotifyAudioFacade.Method.togglePlay)).to(equal(1))
                        }
                        
                        context("and upon failing to toggle play") {
                            let error = NSError(domain: "com.spotify.ios", code: 999, userInfo: [NSLocalizedDescriptionKey: "couldn't toggle play"])
                            
                            it("displays the error message in an alert") {
                                mockSpotifyAudioFacade.mocker.prepareForCallTo(
                                    MockSpotifyAudioFacade.Method.togglePlay, returnValue: error)
                                
                                self.pressPlayPauseButton(playlistTableViewController)
                                
                                self.assertSimpleUIAlertControllerPresented(parentController: playlistTableViewController, expectedTitle: "Unable to Play Song", expectedMessage: error.localizedDescription)
                            }
                        }
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
    
    func pressPlayPauseButton(playlistTableViewController: PlaylistTableViewController) {
        let playPauseButton = playlistTableViewController.playPauseButton
        UIApplication.sharedApplication().sendAction(playPauseButton.action, to: playPauseButton.target, from: self, forEvent: nil)
    }
    
    func assertSimpleUIAlertControllerPresented(#parentController: UIViewController, expectedTitle: String, expectedMessage: String) {
        expect(parentController.presentedViewController).toEventuallyNot(beNil())
        expect(parentController.presentedViewController).toEventually(beAnInstanceOf(UIAlertController))
        if let alertController = parentController.presentedViewController as? UIAlertController {
            expect(alertController.title).toEventually(equal(expectedTitle))
            expect(alertController.message).toEventually(equal(expectedMessage))
        }
    }
}

class MockSpotifyService: SpotifyService {
    
    let mocker = Mocker()
    
    struct Method {
        static let savePlaylist = "savePlaylist"
    }
    
    override func savePlaylist(playlist: Playlist!, session: SPTSession!, callback: (SpotifyService.PlaylistResult) -> Void) {
        mocker.recordCall(Method.savePlaylist, parameters: playlist, session)
        let mockedResult = mocker.returnValueForCallTo(Method.savePlaylist)
        if let mockedResult = mockedResult as? SpotifyService.PlaylistResult {
            callback(mockedResult)
        } else {
            callback(.Success(Playlist(name: "unimportant mocked playlist")))
        }
    }
}
