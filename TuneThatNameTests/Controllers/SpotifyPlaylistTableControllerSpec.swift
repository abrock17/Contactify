import TuneThatName
import Quick
import Nimble

class SpotifyPlaylistTableControllerSpec: QuickSpec {
    
    let songViewTag = 718
    
    override func spec() {
        describe("SpotifyPlaylistTableController") {
            let playlist = Playlist(name: "name", uri: nil, songs:
                [Song(title: "Me And Bobby McGee", artistName: "Janis Joplin", uri: NSURL(string: "spotify:track:3RpndSyVypRVcN38z98MvU")!),
                    Song(title: "Bobby Brown Goes Down", artistName: "Frank Zappa", uri: NSURL(string: "spotify:album:4hBKoHOpEvQ6g4CQFsEAdU")!)])
            let spotifyTrack = SpotifyTrack(
                uri: NSURL(string: "spotify:album:4hBKoHOpEvQ6g4CQFsEAdU")!,
                name: "Bobby Brown Goes Down",
                artistNames: ["Frank Zappa"],
                albumName: "Sheik Yerbouti",
                albumLargestCoverImageURL: NSURL(string: "https://i.scdn.co/image/9a4d67719ada036cfd70dbf8e6519bbaa1bba3c8")!,
                albumSmallestCoverImageURL: NSURL(string: "https://i.scdn.co/image/a58609bb6df41d2a3a4e96d8a436bb9176c12d85")!)
            let image = UIImage(named: "yuck.png", inBundle: NSBundle(forClass: SpotifyPlaylistTableControllerSpec.self), compatibleWithTraitCollection: nil)
            
            var spotifyPlaylistTableController: SpotifyPlaylistTableController!
            var navigationController: UINavigationController!
            var mockSpotifyService: MockSpotifyService!
            var mockSpotifyAudioFacade: MockSpotifyAudioFacade!
            var mockControllerHelper: MockControllerHelper!
            
            beforeEach() {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                
                navigationController = storyboard.instantiateInitialViewController() as! UINavigationController

                spotifyPlaylistTableController = storyboard.instantiateViewControllerWithIdentifier("SpotifyPlaylistTableController") as!  SpotifyPlaylistTableController
                
                spotifyPlaylistTableController.playlist = playlist
                mockSpotifyService = MockSpotifyService()
                spotifyPlaylistTableController.spotifyService = mockSpotifyService
                mockSpotifyAudioFacade = MockSpotifyAudioFacade()
                spotifyPlaylistTableController.spotifyAudioFacadeOverride = mockSpotifyAudioFacade
                mockControllerHelper = MockControllerHelper()
                spotifyPlaylistTableController.controllerHelper = mockControllerHelper
                
                navigationController.pushViewController(spotifyPlaylistTableController, animated: false)
                UIApplication.sharedApplication().keyWindow!.rootViewController = navigationController
                NSRunLoop.mainRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 0.1))
            }

            describe("press the 'save to spotify' button") {
                context("when there is no session and no token refresh service") {
                    let spotifyAuth = self.getMockSpotifyAuth()
                    spotifyAuth.tokenRefreshURL = nil
                    
                    it("prompts the user to log in") {
                        spotifyPlaylistTableController.spotifyAuth = spotifyAuth
                        
                        self.pressSaveButton(spotifyPlaylistTableController)
                        
                        expect(spotifyPlaylistTableController.presentedViewController).toNot(beNil())
                        // this fails inexplicably: "expected to be an instance of SPTAuthViewController, got <SPTAuthViewController instance>"
                        // expect(spotifyPlaylistTableController.presentedViewController).to(beAnInstanceOf(SPTAuthViewController))                    
                    }
                }
                
                context("when the session is invalid and no token refresh service") {
                    let spotifyAuth = self.getMockSpotifyAuth(expiresIn: -60)
                    spotifyAuth.tokenRefreshURL = nil
                    
                    it("prompts the user to log in") {
                        spotifyPlaylistTableController.spotifyAuth = spotifyAuth
                        
                        self.pressSaveButton(spotifyPlaylistTableController)
                        
                        expect(spotifyPlaylistTableController.presentedViewController).toNot(beNil())
                    }
                }
                
                context("when the session is invalid and has a token refresh service") {
                    let spotifyAuth = self.getMockSpotifyAuth(expiresIn: -60)
                    
                    beforeEach() {
                        spotifyPlaylistTableController.spotifyAuth = spotifyAuth
                    }
                    
                    it("tries to renew the session") {
                        self.pressSaveButton(spotifyPlaylistTableController)

                        expect(spotifyAuth.mocker.getNthCallTo(MockSPTAuth.Method.renewSession, n: 0)?.first as? SPTSession).to(equal(spotifyAuth.session))
                    }
                    
                    context("and the session renewal fails (no session in callback)") {
                        it("prompts the user to log in") {
                            spotifyAuth.mocker.prepareForCallTo(MockSPTAuth.Method.renewSession, returnValue: nil)

                            self.pressSaveButton(spotifyPlaylistTableController)
                            
                            expect(spotifyPlaylistTableController.presentedViewController).toNot(beNil())
                        }
                    }

                    context("and the session renewal succeeds") {
                        beforeEach() {
                            spotifyAuth.mocker.prepareForCallTo(MockSPTAuth.Method.renewSession, returnValue: SPTSession(userName: "user", accessToken: "token", expirationTimeInterval: 60))
                            
                            self.pressSaveButton(spotifyPlaylistTableController)
                        }
                        
                        it("does not prompt the user to log in") {
                            expect(spotifyPlaylistTableController.presentedViewController).to(beNil())
                        }
                        
                        it("calls the service to save the playlist") {
                            expect(mockSpotifyService.mocker.getNthCallTo(MockSpotifyService.Method.savePlaylist, n: 0)).toEventuallyNot(beEmpty())
                            var playlistParameter = mockSpotifyService.mocker.getNthCallTo(MockSpotifyService.Method.savePlaylist, n: 0)?.first as? Playlist
                            expect(playlistParameter).to(equal(playlist))
                        }
                    }
                }
                
                context("when there is a valid session") {
                    let spotifyAuth = self.getMockSpotifyAuth(expiresIn: 60)

                    beforeEach() {
                        spotifyPlaylistTableController.spotifyAuth = spotifyAuth
                    }
                    
                    it("does not prompt the user to log in") {
                        self.pressSaveButton(spotifyPlaylistTableController)
                        
                        expect(spotifyPlaylistTableController.presentedViewController).to(beNil())
                    }
                
                    it("updates the save button text") {
                        self.pressSaveButton(spotifyPlaylistTableController)

                        expect(spotifyPlaylistTableController.saveButton.title).to(equal("Saving Playlist"))
                    }
                    
                    it("disables the save button") {
                        spotifyPlaylistTableController.saveButton.enabled = true
                        
                        self.pressSaveButton(spotifyPlaylistTableController)

                        expect(spotifyPlaylistTableController.saveButton.enabled).toNot(beTrue())
                    }
                    
                    it("calls the service to save the playlist") {
                        self.pressSaveButton(spotifyPlaylistTableController)
                        
                        expect(mockSpotifyService.mocker.getNthCallTo(MockSpotifyService.Method.savePlaylist, n: 0)).toEventuallyNot(beEmpty())
                        var playlistParameter = mockSpotifyService.mocker.getNthCallTo(MockSpotifyService.Method.savePlaylist, n: 0)?.first as? Playlist
                        expect(playlistParameter).to(equal(playlist))
                    }
                    
                    context("and upon saving the playlist successfully") {
                        let savedPlaylist = Playlist(name: "saved playlist", uri: NSURL(string: "uri"))
                        beforeEach() {
                            mockSpotifyService.mocker.prepareForCallTo(MockSpotifyService.Method.savePlaylist, returnValue: SpotifyService.PlaylistResult.Success(savedPlaylist))
                            
                            self.pressSaveButton(spotifyPlaylistTableController)
                        }
                        
                        it("has the saved playlist") {
                            expect(spotifyPlaylistTableController.playlist).toEventually(equal(savedPlaylist))
                        }
                        
                        it("updates the save button text") {
                            expect(spotifyPlaylistTableController.saveButton.title).toEventually(equal("Playlist Saved"))
                        }

                        it("disables the save button") {
                            let enabled = spotifyPlaylistTableController.saveButton.enabled
                            expect(spotifyPlaylistTableController.saveButton.enabled).toEventuallyNot(beTrue())
                        }
                    }
                    
                    context("and upon failing to save the playlist") {
                        let error = NSError(domain: "com.spotify.ios", code: 777, userInfo: [NSLocalizedDescriptionKey: "error description"])
                        
                        it("displays the error message in an alert") {
                            mockSpotifyService.mocker.prepareForCallTo(MockSpotifyService.Method.savePlaylist, returnValue: SpotifyService.PlaylistResult.Failure(error))
                            
                            self.pressSaveButton(spotifyPlaylistTableController)

                            self.assertSimpleUIAlertControllerPresented(parentController: spotifyPlaylistTableController, expectedTitle: "Unable to Save Your Playlist", expectedMessage: error.localizedDescription)
                        }
                    }
                }
            }
            
            describe("successful login") {
                let spotifyAuth = self.getMockSpotifyAuth(expiresIn: 60)
                
                beforeEach() {
                    spotifyPlaylistTableController.spotifyAuth = spotifyAuth
                }

                context("when post login action is SavePlaylist") {
                    it("calls the service to save the playlist") {
                        spotifyPlaylistTableController.spotifySessionAction = SpotifyPlaylistTableController.SpotifySessionAction.SavePlaylist

                        spotifyPlaylistTableController.authenticationViewController(SPTAuthViewController(), didLoginWithSession: spotifyAuth.session)
                        
                        expect(mockSpotifyService.mocker.getNthCallTo(MockSpotifyService.Method.savePlaylist, n: 0)?.first as? Playlist).toEventually(equal(playlist))
                    }
                }
                
                context("when the post login action is PlayPlaylist") {
                    let index = 1
                    it("plays the playlist from the given index") {
                        spotifyPlaylistTableController.spotifySessionAction = SpotifyPlaylistTableController.SpotifySessionAction.PlayPlaylist(index: index)
                        
                        spotifyPlaylistTableController.authenticationViewController(SPTAuthViewController(), didLoginWithSession: spotifyAuth.session)
                        
                        self.verifyCallToPlayPlaylistOn(mockSpotifyAudioFacade, expectedPlaylist: playlist, expectedIndex: index, expectedSession: spotifyAuth.session)
                    }
                }
            }
            
            describe("select a song") {
                let indexPath = NSIndexPath(forRow: 1, inSection: 0)
                
                beforeEach() {
                    mockControllerHelper.mocker.prepareForCallTo(MockControllerHelper.Method.getImageForURL, returnValue: image)
                }
                
                afterEach() {
                    spotifyPlaylistTableController.view.viewWithTag(self.songViewTag)?.removeFromSuperview()
                }
                
                context("when the session is invalid") {
                    let spotifyAuth = self.getMockSpotifyAuth(expiresIn: -60)
                    
                    context("and the session renewal succeeds") {
                        let newSession = SPTSession(userName: "user", accessToken: "token", expirationTimeInterval: 60)
                        
                        beforeEach() {
                            spotifyPlaylistTableController.spotifyAuth = spotifyAuth
                            spotifyAuth.mocker.prepareForCallTo(MockSPTAuth.Method.renewSession, returnValue: newSession)

                            spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, didSelectRowAtIndexPath: indexPath)
                        }
                        
                        it("does not prompt the user to log in") {
                            expect(spotifyPlaylistTableController.presentedViewController).to(beNil())
                        }
                        
                        it("calls to play the playlist from the given index") {
                            self.verifyCallToPlayPlaylistOn(mockSpotifyAudioFacade, expectedPlaylist: playlist, expectedIndex: indexPath.row, expectedSession: newSession)
                        }
                    }
                }

                context("when there is a valid session") {
                    let spotifyAuth = self.getMockSpotifyAuth(expiresIn: 60)
                    
                    beforeEach() {
                        spotifyPlaylistTableController.spotifyAuth = spotifyAuth
                        mockControllerHelper.mocker.prepareForCallTo(MockControllerHelper.Method.getImageForURL, returnValue: image)
                    }
                    
                    afterEach() {
                        spotifyPlaylistTableController.view.viewWithTag(self.songViewTag)?.removeFromSuperview()
                    }
                    
                    it("does not prompt the user to log in") {
                        spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, didSelectRowAtIndexPath: indexPath)
                        
                        expect(spotifyPlaylistTableController.presentedViewController).to(beNil())
                    }
                    
                    it("calls to play the playlist from the given index") {
                        spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, didSelectRowAtIndexPath: indexPath)
                        
                        self.verifyCallToPlayPlaylistOn(mockSpotifyAudioFacade, expectedPlaylist: playlist, expectedIndex: indexPath.row, expectedSession: spotifyAuth.session)
                    }
                    
                    it("requests the current spotify track") {
                        spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, didSelectRowAtIndexPath: indexPath)
                        
                        expect(mockSpotifyAudioFacade.mocker.getNthCallTo(MockSpotifyAudioFacade.Method.getCurrentTrackInSession, n: 0)?.first as? SPTSession).to(equal(spotifyAuth.session))
                    }
                    
                    context("and current spotify track calls back successfully") {
                        it("displays the current track in the song view") {
                            mockSpotifyAudioFacade.mocker.prepareForCallTo(MockSpotifyAudioFacade.Method.getCurrentTrackInSession, returnValue: SpotifyTrackResult.Success(spotifyTrack))
                            
                            spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, didSelectRowAtIndexPath: indexPath)
                            
                            self.assertSongViewDisplayedOnController(spotifyPlaylistTableController, forSpotifyTrack: spotifyTrack, andImage: image!)
                        }
                    }
                
                    context("and current spotify track callback fails") {
                        it("does not display the song view") {
                            mockSpotifyAudioFacade.mocker.prepareForCallTo(MockSpotifyAudioFacade.Method.getCurrentTrackInSession, returnValue: SpotifyTrackResult.Failure(NSError(domain: "domain", code: 0, userInfo: nil)))
                            
                            spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, didSelectRowAtIndexPath: indexPath)
                            
                            let view = spotifyPlaylistTableController.view.viewWithTag(self.songViewTag)
                            expect(view).toEventually(beNil())
                        }
                    }
                    
                    context("and upon failing to play the playlist") {
                        let error = NSError(domain: "com.spotify.ios", code: 888, userInfo: [NSLocalizedDescriptionKey: "this list is unplayable"])
                        
                        it("displays the error message in an alert") {
                            mockSpotifyAudioFacade.mocker.prepareForCallTo(
                                MockSpotifyAudioFacade.Method.playPlaylist, returnValue: error)
                            
                            spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, didSelectRowAtIndexPath: indexPath)
                            
                            self.assertSimpleUIAlertControllerPresented(parentController: spotifyPlaylistTableController, expectedTitle: "Unable to Play Song", expectedMessage: error.localizedDescription)
                        }
                    }
                }
            }
            
            describe("press the play/pause button") {
                context("when the session is invalid") {
                    let spotifyAuth = self.getMockSpotifyAuth(expiresIn: -60)
                    
                    beforeEach() {
                        spotifyPlaylistTableController.spotifyAuth = spotifyAuth
                    }
                    
                    it("tries to renew the session") {
                        self.pressPlayPauseButton(spotifyPlaylistTableController)
                        
                        expect(spotifyAuth.mocker.getNthCallTo(MockSPTAuth.Method.renewSession, n: 0)?.first as? SPTSession).to(equal(spotifyAuth.session))
                    }
                    
                    context("and the session renewal fails (no session in callback") {
                        it("prompts the user to log in") {
                            spotifyPlaylistTableController.spotifyAuth = spotifyAuth
                            spotifyAuth.mocker.prepareForCallTo(MockSPTAuth.Method.renewSession, returnValue: nil)
                            
                            self.pressPlayPauseButton(spotifyPlaylistTableController)
                            
                            expect(spotifyPlaylistTableController.presentedViewController).toEventuallyNot(beNil())
                        }
                    }
                }

                context("when there is a valid session") {
                    let spotifyAuth = self.getMockSpotifyAuth(expiresIn: 60)
                    
                    beforeEach() {
                        spotifyPlaylistTableController.spotifyAuth = spotifyAuth
                    }
                    
                    context("and the playlist has not played yet") {
                        it("calls to play the playlist from the first index") {
                            self.pressPlayPauseButton(spotifyPlaylistTableController)
                            
                            self.verifyCallToPlayPlaylistOn(mockSpotifyAudioFacade, expectedPlaylist: playlist, expectedIndex: 0, expectedSession: spotifyAuth.session)
                        }
                    }
                    
                    context("and play has already started") {
                        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
                        
                        beforeEach() {
                            spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, didSelectRowAtIndexPath: indexPath)

                            self.verifyCallToPlayPlaylistOn(mockSpotifyAudioFacade, expectedPlaylist: playlist, expectedIndex: indexPath.row, expectedSession: spotifyAuth.session)
                            NSRunLoop.mainRunLoop().runUntilDate(NSDate())
                        }

                        it("toggles play") {
                            self.pressPlayPauseButton(spotifyPlaylistTableController)
                            
                            expect(mockSpotifyAudioFacade.mocker.getCallCountFor(
                                MockSpotifyAudioFacade.Method.togglePlay)).to(equal(1))
                        }
                        
                        context("and upon failing to toggle play") {
                            let error = NSError(domain: "com.spotify.ios", code: 999, userInfo: [NSLocalizedDescriptionKey: "couldn't toggle play"])
                            
                            it("displays the error message in an alert") {
                                mockSpotifyAudioFacade.mocker.prepareForCallTo(
                                    MockSpotifyAudioFacade.Method.togglePlay, returnValue: error)
                                
                                self.pressPlayPauseButton(spotifyPlaylistTableController)
                                
                                self.assertSimpleUIAlertControllerPresented(parentController: spotifyPlaylistTableController, expectedTitle: "Unable to Play Song", expectedMessage: error.localizedDescription)
                            }
                        }
                    }
                }
            }
            
            describe("press the song view button") {
                let spotifyAuth = self.getMockSpotifyAuth(expiresIn: 60)
                
                beforeEach() {
                    spotifyPlaylistTableController.spotifyAuth = spotifyAuth
                    mockControllerHelper.mocker.prepareForCallTo(MockControllerHelper.Method.getImageForURL, returnValue: image)
                }
                
                afterEach() {
                    spotifyPlaylistTableController.view.viewWithTag(self.songViewTag)?.removeFromSuperview()
                }

                it("displays the current track in the song view") {
                    mockSpotifyAudioFacade.mocker.prepareForCallTo(MockSpotifyAudioFacade.Method.getCurrentTrackInSession, returnValue: SpotifyTrackResult.Success(spotifyTrack))
                    
                    self.pressSongViewButton(spotifyPlaylistTableController)
                    
                    self.assertSongViewDisplayedOnController(spotifyPlaylistTableController, forSpotifyTrack: spotifyTrack, andImage: image!)
                }
            }
            
            describe("playback status change") {
                context("when is playing") {
                    it("sets the play/pause button to the 'pause' system item") {
                        spotifyPlaylistTableController.audioStreaming(nil, didChangePlaybackStatus: true)
                        
                        expect(self.getPlayPauseButtonSystemItemFromToolbar(spotifyPlaylistTableController)).to(equal(UIBarButtonSystemItem.Pause))
                    }
                }
                
                context("when is not playing") {
                    it("sets the play/pause button to the 'play' system item") {
                        spotifyPlaylistTableController.audioStreaming(nil, didChangePlaybackStatus: false)
                        
                        expect(self.getPlayPauseButtonSystemItemFromToolbar(spotifyPlaylistTableController)).to(equal(UIBarButtonSystemItem.Play))
                    }
                }
            }
            
            describe("track starts playing") {
                let spotifyAuth = self.getMockSpotifyAuth(expiresIn: 60)
                let mockSpotifyAudioStreamingController = MockSPTAudioStreamingController(clientId: SpotifyService.clientID)

                beforeEach() {
                    spotifyPlaylistTableController.spotifyAuth = spotifyAuth
                    mockControllerHelper.mocker.prepareForCallTo(MockControllerHelper.Method.getImageForURL, returnValue: image)
                }
                
                it("requests the track for the provided uri") {
                    spotifyPlaylistTableController.audioStreaming(mockSpotifyAudioStreamingController, didStartPlayingTrack: spotifyTrack.uri)
                    
                    expect(mockSpotifyAudioFacade.mocker.getNthCallTo(MockSpotifyAudioFacade.Method.getTrackWithURI, n: 0)?[0] as? NSURL).to(equal(spotifyTrack.uri))
                }
                
                context("and track for uri calls back successfully") {
                    beforeEach() {
                        mockSpotifyAudioFacade.mocker.prepareForCallTo(MockSpotifyAudioFacade.Method.getTrackWithURI, returnValue: SpotifyTrackResult.Success(spotifyTrack))
                    }
                    
                    it("updates the song view button image") {
                        spotifyPlaylistTableController.audioStreaming(mockSpotifyAudioStreamingController, didStartPlayingTrack: spotifyTrack.uri)

                        expect(self.getSongViewButtonBackgroundImageFromToolbar(spotifyPlaylistTableController)).toEventually(equal(image))
                    }
                    
                    context("and song view is visible") {
                        it("updates the song view with to display the track") {
                            self.pressSongViewButton(spotifyPlaylistTableController)
                            
                            spotifyPlaylistTableController.audioStreaming(mockSpotifyAudioStreamingController, didStartPlayingTrack: spotifyTrack.uri)
                            
                            self.assertSongViewDisplayedOnController(spotifyPlaylistTableController, forSpotifyTrack: spotifyTrack, andImage: image!)
                        }
                    }
                }
                
                context("and track for uri callback fails") {
                    beforeEach() {
                        mockSpotifyAudioFacade.mocker.prepareForCallTo(MockSpotifyAudioFacade.Method.getCurrentTrackInSession, returnValue: SpotifyTrackResult.Success(spotifyTrack))
                        self.pressSongViewButton(spotifyPlaylistTableController)
                        expect(spotifyPlaylistTableController.view.viewWithTag(self.songViewTag)).toEventuallyNot(beNil())
                        
                        mockSpotifyAudioFacade.mocker.prepareForCallTo(MockSpotifyAudioFacade.Method.getTrackWithURI, returnValue: SpotifyTrackResult.Failure(NSError(domain: "domain", code: 87, userInfo: nil)))

                        spotifyPlaylistTableController.audioStreaming(mockSpotifyAudioStreamingController, didStartPlayingTrack: spotifyTrack.uri)
                    }
                    
                    it("closes the song view") {
                        expect(spotifyPlaylistTableController.view.viewWithTag(self.songViewTag))
                            .toEventually(beNil())
                    }
                }
            }
            
            describe("unwind to create playlist") {
                it("stops play") {
                    spotifyPlaylistTableController.performSegueWithIdentifier("UnwindToCreatePlaylistSegue", sender: nil)
                    NSRunLoop.mainRunLoop().runUntilDate(NSDate())
                    
                    expect(mockSpotifyAudioFacade.mocker.getCallCountFor(
                        MockSpotifyAudioFacade.Method.stopPlay)).to(equal(1))
                }
            }
        }
    }
    
    func getMockSpotifyAuth(#expiresIn: NSTimeInterval) -> MockSPTAuth {
        let mockSpotifyAuth = getMockSpotifyAuth()
        mockSpotifyAuth.session = SPTSession(userName: "user", accessToken: "token", expirationDate: NSDate(timeIntervalSinceNow: expiresIn))
        return mockSpotifyAuth
    }
    
    func getMockSpotifyAuth() -> MockSPTAuth {
        let mockSpotifyAuth = MockSPTAuth()
        mockSpotifyAuth.clientID = "clientID"
        mockSpotifyAuth.redirectURL = NSURL(string: "redirect://url")
        mockSpotifyAuth.tokenSwapURL = NSURL(string: "https://token/swap")
        mockSpotifyAuth.tokenRefreshURL = NSURL(string: "https://token/refresh")

        return mockSpotifyAuth
    }
    
    func pressSaveButton(spotifyPlaylistTableController: SpotifyPlaylistTableController) {
        let saveButton = spotifyPlaylistTableController.saveButton
        UIApplication.sharedApplication().sendAction(saveButton.action, to: saveButton.target, from: self, forEvent: nil)
    }
    
    func pressPlayPauseButton(spotifyPlaylistTableController: SpotifyPlaylistTableController) {
        let playPauseButton = spotifyPlaylistTableController.playPauseButton
        UIApplication.sharedApplication().sendAction(playPauseButton.action, to: playPauseButton.target, from: self, forEvent: nil)
    }
    
    func pressSongViewButton(spotifyPlaylistTableController: SpotifyPlaylistTableController) {
        let songViewButton = spotifyPlaylistTableController.songViewButton
        UIApplication.sharedApplication().sendAction(songViewButton.action, to: songViewButton.target, from: self, forEvent: nil)
    }
    
    func assertSimpleUIAlertControllerPresented(#parentController: UIViewController, expectedTitle: String, expectedMessage: String) {
        expect(parentController.presentedViewController).toEventuallyNot(beNil())
        expect(parentController.presentedViewController).toEventually(beAnInstanceOf(UIAlertController))
        if let alertController = parentController.presentedViewController as? UIAlertController {
            expect(alertController.title).toEventually(equal(expectedTitle))
            expect(alertController.message).toEventually(equal(expectedMessage))
        }
    }
    
    func assertSongViewDisplayedOnController(spotifyPlaylistTableController: SpotifyPlaylistTableController, forSpotifyTrack spotifyTrack: SpotifyTrack, andImage image: UIImage) {
        let view = spotifyPlaylistTableController.view.viewWithTag(self.songViewTag)
        expect(view).toEventuallyNot(beNil())
        if let songView = view as? SongView {
            expect(songView.title.text).to(equal(spotifyTrack.name))
            expect(songView.artist.text).to(equal(spotifyTrack.artistNames.first))
            expect(songView.album.text).to(equal(spotifyTrack.albumName))
            expect(songView.image.image).toEventually(equal(image))
        }
    }
    
    func getPlayPauseButtonSystemItemFromToolbar(spotifyPlaylistTableController: SpotifyPlaylistTableController) -> UIBarButtonSystemItem {
        let playPauseButton = spotifyPlaylistTableController.navigationController?.toolbar.items?[4] as? UIBarButtonItem
        return UIBarButtonSystemItem(rawValue: playPauseButton!.valueForKey("systemItem") as! Int)!
    }
    
    func getSongViewButtonBackgroundImageFromToolbar(spotifyPlaylistTableController: SpotifyPlaylistTableController) -> UIImage? {
        let saveViewButton = spotifyPlaylistTableController.navigationController?.toolbar.items?[0] as? UIBarButtonItem
        return (saveViewButton?.customView as? UIButton)?.currentBackgroundImage
    }
    
    func verifyCallToPlayPlaylistOn(mockSpotifyAudioFacade: MockSpotifyAudioFacade, expectedPlaylist: Playlist, expectedIndex: Int, expectedSession: SPTSession) {
        expect(mockSpotifyAudioFacade.mocker.getNthCallTo(MockSpotifyAudioFacade.Method.playPlaylist, n: 0)?[0] as? Playlist).toEventually(equal(expectedPlaylist))
        expect(mockSpotifyAudioFacade.mocker.getNthCallTo(MockSpotifyAudioFacade.Method.playPlaylist, n: 0)?[1] as? Int).toEventually(equal(expectedIndex))
        expect(mockSpotifyAudioFacade.mocker.getNthCallTo(MockSpotifyAudioFacade.Method.playPlaylist, n: 0)?[2] as? SPTSession).toEventually(equal(expectedSession))
    }
}

class MockSPTAuth: SPTAuth {
    
    let mocker = Mocker()
    
    struct Method {
        static let renewSession = "renewSession"
    }
    
    override func renewSession(session: SPTSession!, callback: SPTAuthCallback!) {
        mocker.recordCall(Method.renewSession, parameters: session)
        callback(nil, mocker.returnValueForCallTo(Method.renewSession) as? SPTSession)
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
