import TuneThatName
import Quick
import Nimble

class SpotifySongSelectionTableControllerSpec: QuickSpec {
    
    var callbackSong: Song? = nil
    var callbackContact: Contact? = nil
    
    func songSelectionCompletionHandler(song: Song, contact: Contact?) {
        self.callbackSong = song
        self.callbackContact = contact
    }
    
    override func spec() {
        describe("SpotifySongSelectionTableController") {
            var spotifySongSelectionTableController: SpotifySongSelectionTableController!
            var navigationController: UINavigationController!
            var mockEchoNestService: MockEchoNestService!
            var mockSpotifyAudioFacade: MockSpotifyAudioFacade!
            var mockSpotifyUserService: MockSpotifyUserService!
            var mockControllerHelper: MockControllerHelper!

            let userLocale = "SE"
            let spotifyUser: SpotifyUser = SpotifyUser(username: "yourmom", territory: userLocale)
            let searchContact = Contact(id: 23, firstName: "Michael", lastName: "Jordan")
            let resultSongList = [
                Song(title: "Michael", artistName: "Franz Ferdinand", uri: NSURL(string: "spotify:track:1HcYhFRFQVSu8CGc0dl9to")!),
                Song(title: "The Ballad of Michael Valentine", artistName: "The Killers", uri:  NSURL(string: "spotify:track:2MwNreqilyOvET5lEiv9E1")!),
                Song(title: "Political Song for Michael Jackson to Sing", artistName: "Minutemen", uri: NSURL(string: "spotify:track:4dSug8anlR9XafooHaRbBR")!)
            ]
            let spotifyTrack = SpotifyTrack(uri: NSURL(string: "spotify:track:2MwNreqilyOvET5lEiv9E1")!,
                name: "The Ballad of Michael Valentine",
                artistNames: ["The Killers"],
                albumName: "Somebody Told Me",
                albumLargestCoverImageURL: NSURL(string: "https://i.scdn.co/image/4568ca59da9845fd3c55bcbdecfebac76433a066")!,
                albumSmallestCoverImageURL: NSURL(string: "https://i.scdn.co/image/850d1ff80d51e31c33ccc49b33227b0d12c8cd1e")!
            )
            let image = UIImage(named: "yuck.png", inBundle: NSBundle(forClass: SpotifyPlaylistTableControllerSpec.self), compatibleWithTraitCollection: nil)
            
            beforeEach() {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                
                navigationController = storyboard.instantiateInitialViewController() as! UINavigationController
                
                spotifySongSelectionTableController = storyboard.instantiateViewControllerWithIdentifier("SpotifySongSelectionTableController") as!  SpotifySongSelectionTableController
                spotifySongSelectionTableController.searchContact = searchContact
                spotifySongSelectionTableController.songSelectionCompletionHandler = self.songSelectionCompletionHandler
                mockEchoNestService = MockEchoNestService()
                spotifySongSelectionTableController.echoNestService = mockEchoNestService
                mockSpotifyAudioFacade = MockSpotifyAudioFacade()
                spotifySongSelectionTableController.spotifyAudioFacadeOverride = mockSpotifyAudioFacade
                mockSpotifyUserService = MockSpotifyUserService()
                spotifySongSelectionTableController.spotifyUserService = mockSpotifyUserService
                mockControllerHelper = MockControllerHelper()
                spotifySongSelectionTableController.controllerHelper = mockControllerHelper
            }
            
            describe("view load") {
                it("disables the select button") {
                    self.loadViewForController(spotifySongSelectionTableController, withNavigationController: navigationController)

                    expect(spotifySongSelectionTableController.selectButton.enabled).toEventually(beFalse())
                }
                
                it("retrieves the current user from the user service") {
                    self.loadViewForController(spotifySongSelectionTableController, withNavigationController: navigationController)
                    
                    expect(mockSpotifyUserService.mocker.getCallCountFor(MockSpotifyUserService.Method.retrieveCurrentUser)).toEventually(equal(1))
                }
                
                context("and the user service calls back with an error") {
                    let userServiceError = NSError(domain: "DOMAIN", code: 234, userInfo: [NSLocalizedDescriptionKey: "couldn't get no user"])
                    
                    it("calls back with the same error") {
                        mockSpotifyUserService.mocker.prepareForCallTo(MockSpotifyUserService.Method.retrieveCurrentUser, returnValue: SpotifyUserService.UserResult.Failure(userServiceError))
                        
                        self.loadViewForController(spotifySongSelectionTableController, withNavigationController: navigationController)
                        
                        self.assertSimpleUIAlertControllerPresentedOnController(
                            spotifySongSelectionTableController, withTitle: "Unable to Search for Songs", andMessage: userServiceError.localizedDescription)
                    }
                }
                
                context("and user service calls back with a user") {
                    beforeEach() {
                        mockSpotifyUserService.mocker.prepareForCallTo(MockSpotifyUserService.Method.retrieveCurrentUser, returnValue: SpotifyUserService.UserResult.Success(spotifyUser))
                    }
                    
                    it("searches for songs from the echo nest service") {
                        self.loadViewForController(spotifySongSelectionTableController, withNavigationController: navigationController)
                        
                        expect(mockEchoNestService.mocker.getCallCountFor(MockEchoNestService.Method.findSongs))
                            .toEventually(equal(1))
                        expect(mockEchoNestService.mocker.getNthCallTo(
                            MockEchoNestService.Method.findSongs, n: 0)?[0] as? String)
                            .toEventually(equal(searchContact.searchString))
                        let expectedSongPreferences = SongPreferences()
                        expect(mockEchoNestService.mocker.getNthCallTo(
                            MockEchoNestService.Method.findSongs, n: 0)?[1] as? SongPreferences)
                            .toEventually(equal(expectedSongPreferences))
                        expect(mockEchoNestService.mocker.getNthCallTo(
                            MockEchoNestService.Method.findSongs, n: 0)?[2] as? Int)
                            .toEventually(equal(50))
                        expect(mockEchoNestService.mocker.getNthCallTo(
                            MockEchoNestService.Method.findSongs, n: 0)?[3] as? String)
                            .toEventually(equal(userLocale))
                    }
                    
                    context("when the song search returns an error") {
                        let error = NSError(domain: "domain", code: 0, userInfo: [NSLocalizedDescriptionKey: "ain't no songs for this name"])
                        it("displays the error message in an alert") {
                            mockEchoNestService.mocker.prepareForCallTo(MockEchoNestService.Method.findSongs, returnValue: EchoNestService.SongsResult.Failure(error))
                            
                            self.loadViewForController(spotifySongSelectionTableController, withNavigationController: navigationController)
                            
                            self.assertSimpleUIAlertControllerPresentedOnController(
                                spotifySongSelectionTableController, withTitle: "Unable to Search for Songs", andMessage: error.localizedDescription)
                        }
                    }
                    
                    context("when the song search returns the echo nest 'unknown error'") {
                        let error = NSError(domain: Constants.Error.Domain, code: Constants.Error.EchonestUnknownErrorCode, userInfo: [NSLocalizedDescriptionKey: "unknown error"])
                        it("displays the 'no songs found' alert") {
                            mockEchoNestService.mocker.prepareForCallTo(MockEchoNestService.Method.findSongs, returnValue: EchoNestService.SongsResult.Failure(error))
                            
                            self.loadViewForController(spotifySongSelectionTableController, withNavigationController: navigationController)
                            
                            self.assertSimpleUIAlertControllerPresentedOnController(
                                spotifySongSelectionTableController,
                                withTitle: "No Songs Found\nfor \"\(searchContact.searchString)\"",
                                andMessage: "Try searching with a different name. " +
                                "Results are best when you use only a first name."
                            )
                        }
                    }
                    
                    context("when the song search returns a successful empty result") {
                        it ("displays the 'no songs found' alert") {
                            mockEchoNestService.mocker.prepareForCallTo(MockEchoNestService.Method.findSongs, returnValue: EchoNestService.SongsResult.Success([Song]()))
                            
                            self.loadViewForController(spotifySongSelectionTableController, withNavigationController: navigationController)
                            
                            self.assertSimpleUIAlertControllerPresentedOnController(
                                spotifySongSelectionTableController,
                                withTitle: "No Songs Found\nfor \"\(searchContact.searchString)\"",
                                andMessage: "Try searching with a different name. " +
                                    "Results are best when you use only a first name."
                            )
                        }
                    }
                    
                    context("when the song search returns a successful result") {
                        it("displays the expected results in the table") {
                            mockEchoNestService.mocker.prepareForCallTo(MockEchoNestService.Method.findSongs, returnValue: EchoNestService.SongsResult.Success(resultSongList))
                            
                            self.loadViewForController(spotifySongSelectionTableController, withNavigationController: navigationController)
                            
                            expect(
                                spotifySongSelectionTableController.tableView(
                                    spotifySongSelectionTableController.tableView, numberOfRowsInSection: 0))
                                .toEventually(equal(resultSongList.count))
                            for (index, song) in resultSongList.enumerate() {
                                expect(
                                    spotifySongSelectionTableController.tableView(
                                        spotifySongSelectionTableController.tableView,
                                        cellForRowAtIndexPath: NSIndexPath(forRow: index, inSection: 0)).textLabel?.text)
                                    .toEventually(equal(song.title))
                                expect(
                                    spotifySongSelectionTableController.tableView(
                                        spotifySongSelectionTableController.tableView,
                                        cellForRowAtIndexPath: NSIndexPath(forRow: index, inSection: 0)).detailTextLabel?.text)
                                    .toEventually(equal(song.displayArtistName))
                            }
                        }
                    }
                }
            }
            
            context("when the view loads successfully") {
                let indexPath = NSIndexPath(forRow: 1, inSection: 0)

                beforeEach() {
                    mockSpotifyUserService.mocker.prepareForCallTo(MockSpotifyUserService.Method.retrieveCurrentUser, returnValue: SpotifyUserService.UserResult.Success(spotifyUser))
                    mockEchoNestService.mocker.prepareForCallTo(MockEchoNestService.Method.findSongs, returnValue: EchoNestService.SongsResult.Success(resultSongList))
                    
                    self.loadViewForController(spotifySongSelectionTableController, withNavigationController: navigationController)
                    expect(spotifySongSelectionTableController.songs).toEventually(equal(resultSongList))
                }
                
                describe("did select a row") {
                    it("enables the select button") {
                        spotifySongSelectionTableController.tableView(spotifySongSelectionTableController.tableView, didSelectRowAtIndexPath: indexPath)
                        
                        expect(spotifySongSelectionTableController.selectButton.enabled).toEventually(beTrue())
                    }
                    
                    it("plays the track") {
                        spotifySongSelectionTableController.tableView(
                            spotifySongSelectionTableController.tableView, didSelectRowAtIndexPath: indexPath)

                        expect(mockSpotifyAudioFacade.mocker.getNthCallTo(MockSpotifyAudioFacade.Method.playTracksForURIs, n: 0)?[0] as? [NSURL]).toEventually(equal([resultSongList[1].uri]))
                        expect(mockSpotifyAudioFacade.mocker.getNthCallTo(MockSpotifyAudioFacade.Method.playTracksForURIs, n: 0)?[1] as? Int).toEventually(equal(0))
                    }
                    
                    context("when the audio facade returns an error") {
                        let error = NSError(domain: "com.spotify.ios", code: 888, userInfo: [NSLocalizedDescriptionKey: "how can you listen to this garbage"])
                        
                        it("displays the error message in an alert") {
                            mockSpotifyAudioFacade.mocker.prepareForCallTo(
                                MockSpotifyAudioFacade.Method.playTracksForURIs, returnValue: error)
                            
                            spotifySongSelectionTableController.tableView(spotifySongSelectionTableController.tableView, didSelectRowAtIndexPath: indexPath)
                            
                            self.assertSimpleUIAlertControllerPresentedOnController(spotifySongSelectionTableController, withTitle: "Unable to Play Song", andMessage: error.localizedDescription)
                        }
                        
                        context("and the error is due to login cancellation") {
                            let loginCanceledError = NSError(domain: Constants.Error.Domain, code: Constants.Error.SpotifyLoginCanceledCode, userInfo: [:])
                            
                            it("does not present any controller") {
                                mockSpotifyAudioFacade.mocker.prepareForCallTo(
                                    MockSpotifyAudioFacade.Method.playTracksForURIs, returnValue: loginCanceledError)
                                
                                spotifySongSelectionTableController.tableView(spotifySongSelectionTableController.tableView, didSelectRowAtIndexPath: indexPath)
                                NSRunLoop.mainRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 0.1))
                                
                                expect(spotifySongSelectionTableController.presentedViewController).toEventually(beNil())
                            }
                        }
                    }
                }
                
                describe("press the select button") {
                    it("calls the completion handler") {
                        spotifySongSelectionTableController.tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: .None)
                        
                        self.pressSelectButton(spotifySongSelectionTableController)
                        
                        expect(self.callbackSong).toEventually(equal(resultSongList[indexPath.row]))
                        expect(self.callbackContact).toEventually(equal(searchContact))
                    }
                }
                
                describe("press the play/pause button") {
                    context("when audio facade has no current track") {
                        it("calls to play the first track") {
                            mockSpotifyAudioFacade.mocker.prepareForCallTo(MockSpotifyAudioFacade.Method.getCurrentSpotifyTrack, returnValue: nil)
                            
                            self.pressPlayPauseButton(spotifySongSelectionTableController)
                            
                            expect(mockSpotifyAudioFacade.mocker.getNthCallTo(MockSpotifyAudioFacade.Method.playTracksForURIs, n: 0)?[0] as? [NSURL]).toEventually(equal([resultSongList[0].uri]))
                            expect(mockSpotifyAudioFacade.mocker.getNthCallTo(MockSpotifyAudioFacade.Method.playTracksForURIs, n: 0)?[1] as? Int).toEventually(equal(0))
                        }
                    }
                    
                    context("when audio facade has a current track") {
                        beforeEach() {
                            mockSpotifyAudioFacade.mocker.prepareForCallTo(MockSpotifyAudioFacade.Method.getCurrentSpotifyTrack, returnValue: spotifyTrack)
                        }
                        
                        it("toggles play") {
                            self.pressPlayPauseButton(spotifySongSelectionTableController)
                            
                            expect(mockSpotifyAudioFacade.mocker.getCallCountFor(
                                MockSpotifyAudioFacade.Method.togglePlay)).toEventually(equal(1))
                        }

                        context("and upon failing to toggle play") {
                            let error = NSError(domain: "com.spotify.ios", code: 999, userInfo: [NSLocalizedDescriptionKey: "something went terribly wrong"])
                            
                            it("displays the error message in an alert") {
                                mockSpotifyAudioFacade.mocker.prepareForCallTo(
                                    MockSpotifyAudioFacade.Method.togglePlay, returnValue: error)
                                
                                self.pressPlayPauseButton(spotifySongSelectionTableController)
                                
                                self.assertSimpleUIAlertControllerPresentedOnController(spotifySongSelectionTableController, withTitle: "Unable to Play Song", andMessage: error.localizedDescription)
                            }
                        }
                    }

                    describe("press the song view button") {
                        it("shows the spotify track view") {
                            self.pressSongViewButton(spotifySongSelectionTableController)
                            
                            expect(spotifySongSelectionTableController.presentedViewController).toEventually(
                                beAnInstanceOf(SpotifyTrackViewController))
                            let spotifyTrackViewController = spotifySongSelectionTableController.presentedViewController as? SpotifyTrackViewController
                            expect(spotifyTrackViewController?.spotifyAudioFacade as? MockSpotifyAudioFacade).to(beIdenticalTo(mockSpotifyAudioFacade))
                        }
                    }
                    
                    describe("playback status change") {
                        context("when is playing") {
                            it("sets the play/pause button to the 'pause' system item") {
                                spotifySongSelectionTableController.changedPlaybackStatus(true)
                                
                                expect(self.getPlayPauseButtonSystemItemFromToolbar(spotifySongSelectionTableController)).to(equal(UIBarButtonSystemItem.Pause))
                            }
                        }
                        
                        context("when is not playing") {
                            it("sets the play/pause button to the 'play' system item") {
                                spotifySongSelectionTableController.changedPlaybackStatus(false)
                                
                                expect(self.getPlayPauseButtonSystemItemFromToolbar(spotifySongSelectionTableController)).to(equal(UIBarButtonSystemItem.Play))
                            }
                        }
                    }
                    
                    describe("current track change") {
                        beforeEach() {
                            mockControllerHelper.mocker.prepareForCallTo(MockControllerHelper.Method.getImageForURL, returnValue: image)
                        }
                        
                        context("and it is not nil") {
                            beforeEach() {
                                spotifySongSelectionTableController.changedCurrentTrack(spotifyTrack)
                            }
                            
                            it("updates the selected song in the table") {
                                expect(spotifySongSelectionTableController.tableView.indexPathForSelectedRow?.row)
                                    .toEventually(equal(1))
                            }
                            
                            it("updates the song view button image") {
                                expect(self.getSongViewButtonBackgroundImageFromToolbar(spotifySongSelectionTableController)).toEventually(equal(image))
                            }
                        }
                    }
                }
            }
        }
    }
    
    func loadViewForController(viewController: UIViewController, withNavigationController navigationController: UINavigationController) {
        navigationController.pushViewController(viewController, animated: false)
        UIApplication.sharedApplication().keyWindow!.rootViewController = navigationController
    }
    
    func assertSimpleUIAlertControllerPresentedOnController(parentController: UIViewController, withTitle expectedTitle: String, andMessage expectedMessage: String) {
        expect(parentController.presentedViewController).toEventuallyNot(beNil())
        expect(parentController.presentedViewController).toEventually(beAnInstanceOf(UIAlertController))
        if let alertController = parentController.presentedViewController as? UIAlertController {
            expect(alertController.title).toEventually(equal(expectedTitle))
            expect(alertController.message).toEventually(equal(expectedMessage))
        }
    }
    
    func pressSelectButton(spotifySongSelectionTableController: SpotifySongSelectionTableController) {
        UIApplication.sharedApplication().sendAction(spotifySongSelectionTableController.selectButton.action,
            to: spotifySongSelectionTableController.selectButton.target, from: self, forEvent: nil)
    }
    
    func pressPlayPauseButton(spotifySongSelectionTableController: SpotifySongSelectionTableController) {
        UIApplication.sharedApplication().sendAction(spotifySongSelectionTableController.playPauseButton.action,
            to: spotifySongSelectionTableController.playPauseButton.target, from: self, forEvent: nil)
    }
    
    func pressSongViewButton(spotifySongSelectionTableController: SpotifySongSelectionTableController) {
        UIApplication.sharedApplication().sendAction(spotifySongSelectionTableController.songViewButton.action,
            to: spotifySongSelectionTableController.songViewButton.target, from: self, forEvent: nil)
    }
    
    func getPlayPauseButtonSystemItemFromToolbar(spotifySongSelectionTableController: SpotifySongSelectionTableController) -> UIBarButtonSystemItem {
        let playPauseButton = spotifySongSelectionTableController.toolbarItems?[2]
        return UIBarButtonSystemItem(rawValue: playPauseButton!.valueForKey("systemItem") as! Int)!
    }
    
    func getSongViewButtonBackgroundImageFromToolbar(spotifySongSelectionTableController: SpotifySongSelectionTableController) -> UIImage? {
        let songViewButton = spotifySongSelectionTableController.toolbarItems?[0]
        return (songViewButton?.customView as? UIButton)?.currentBackgroundImage
    }
}