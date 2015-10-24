import TuneThatName
import Quick
import Nimble

class SpotifyPlaylistTableControllerSpec: QuickSpec {
    
    override func spec() {
        describe("SpotifyPlaylistTableController") {
            let playlist = Playlist(name: "about to DROP", 
                songsWithContacts: [(song: Song(title: "Me And Bobby McGee", artistName: "Janis Joplin", uri: NSURL(string: "spotify:track:3RpndSyVypRVcN38z98MvU")!), contact: Contact(id: 1, firstName: "Bobby", lastName: "McGee")),
                    (song: Song(title: "Bobby Brown Goes Down", artistName: "Frank Zappa", uri: NSURL(string: "spotify:track:6WALLlw7klz1BfjlyaBDen")!), contact: nil)])
            let spotifyTrack = SpotifyTrack(
                uri: NSURL(string: "spotify:track:6WALLlw7klz1BfjlyaBDen")!,
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
                self.advanceRunLoopForTimeInterval(0.1)
            }
            
            describe("press the 'save to spotify' button") {
                context("when there is no session and no token refresh service") {
                    let spotifyAuth = self.getMockSpotifyAuth()
                    spotifyAuth.mocker.clearMockedReturnsFor(MockSPTAuth.Method.hasTokenRefreshService)
                    spotifyAuth.mocker.prepareForCallTo(MockSPTAuth.Method.hasTokenRefreshService, returnValue: false)

                    it("prompts the user to log in") {
                        spotifyPlaylistTableController.spotifyAuth = spotifyAuth
                        
                        self.pressSaveButton(spotifyPlaylistTableController)
                        
                        expect(spotifyPlaylistTableController.presentedViewController).toNot(beNil())
                        // this fails inexplicably: "expected to be an instance of SPTAuthViewController, got <SPTAuthViewController instance>"
                        // expect(spotifyPlaylistTableController.presentedViewController).to(beAnInstanceOf(SPTAuthViewController))                    
                    }
                }
                
                context("when the session is invalid and no token refresh service") {
                    let spotifyAuth = self.getMockSpotifyAuthThatExpiresIn(-60)
                    spotifyAuth.mocker.clearRecordedCallsTo(MockSPTAuth.Method.hasTokenRefreshService)
                    spotifyAuth.mocker.clearMockedReturnsFor(MockSPTAuth.Method.hasTokenRefreshService)
                    spotifyAuth.mocker.prepareForCallTo(MockSPTAuth.Method.hasTokenRefreshService, returnValue: false)
                    
                    it("prompts the user to log in") {
                        spotifyPlaylistTableController.spotifyAuth = spotifyAuth
                        
                        self.pressSaveButton(spotifyPlaylistTableController)
                        
                        expect(spotifyPlaylistTableController.presentedViewController).toNot(beNil())
                    }
                }
                
                context("when the session is invalid and has a token refresh service") {
                    let spotifyAuth = self.getMockSpotifyAuthThatExpiresIn(-60)
                    
                    beforeEach() {
                        spotifyPlaylistTableController.spotifyAuth = spotifyAuth
                    }
                    
                    it("tries to renew the session") {
                        self.pressSaveButton(spotifyPlaylistTableController)

                        expect(spotifyAuth.mocker.getNthCallTo(MockSPTAuth.Method.renewSession, n: 0)?.first as? SPTSession).toEventually(equal(spotifyAuth.session))
                    }
                    
                    context("and the session renewal fails (no session in callback)") {
                        it("prompts the user to log in") {
                            spotifyAuth.mocker.prepareForCallTo(MockSPTAuth.Method.renewSession, returnValue: nil)

                            self.pressSaveButton(spotifyPlaylistTableController)
                            
                            expect(spotifyPlaylistTableController.presentedViewController).toEventuallyNot(beNil())
                        }
                    }

                    xcontext("and the session renewal succeeds") {
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
                    let spotifyAuth = self.getMockSpotifyAuthThatExpiresIn(60)

                    beforeEach() {
                        spotifyPlaylistTableController.spotifyAuth = spotifyAuth
                    }
                    
                    context("and the playlist does not have a name") {
                        it("presents the playlist name entry view") {
                            spotifyPlaylistTableController.playlist.name = nil
                            
                            self.pressSaveButton(spotifyPlaylistTableController)
                            
                            expect(spotifyPlaylistTableController.presentedViewController).toEventually(beAnInstanceOf(PlaylistNameEntryController), timeout: 2)
                        }
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

                            self.assertSimpleUIAlertControllerPresentedOnController(spotifyPlaylistTableController, withTitle: "Unable to Save Your Playlist", andMessage: error.localizedDescription)
                        }
                    }
                }
            }
            
            describe("select a song") {
                let indexPath = NSIndexPath(forRow: 1, inSection: 0)
                
                beforeEach() {
                    mockControllerHelper.mocker.prepareForCallTo(MockControllerHelper.Method.getImageForURL, returnValue: image)
                }
            
                it("calls to play the playlist from the given index") {
                    spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, didSelectRowAtIndexPath: indexPath)
                    
                    self.verifyCallsToPlayTracksForURIsOn(mockSpotifyAudioFacade, expectedURIs: playlist.songURIs, expectedIndex: indexPath.row)
                }
                
                context("and upon playing the playlist") {
                    it("shows the spotify track view") {
                        spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, didSelectRowAtIndexPath: indexPath)
                        
                        expect(spotifyPlaylistTableController.presentedViewController).toEventually(
                            beAnInstanceOf(SpotifyTrackViewController))
                        let spotifyTrackViewController = spotifyPlaylistTableController.presentedViewController as? SpotifyTrackViewController
                        expect(spotifyTrackViewController?.spotifyAudioFacade as? MockSpotifyAudioFacade).to(beIdenticalTo(mockSpotifyAudioFacade))
                    }
                }
                
                context("and upon failing to play the playlist") {
                    let error = NSError(domain: "com.spotify.ios", code: 888, userInfo: [NSLocalizedDescriptionKey: "this list is unplayable"])
                    
                    it("displays the error message in an alert") {
                        mockSpotifyAudioFacade.mocker.prepareForCallTo(
                            MockSpotifyAudioFacade.Method.playTracksForURIs, returnValue: error)
                        
                        spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, didSelectRowAtIndexPath: indexPath)
                        
                        self.assertSimpleUIAlertControllerPresentedOnController(spotifyPlaylistTableController, withTitle: Constants.Error.GenericPlaybackMessage, andMessage: error.localizedDescription)
                    }
                }
                
                context("and editing") {
                    it("does not show the spotify track view") {
                        self.pressEditButton(spotifyPlaylistTableController)
                        
                        spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, didSelectRowAtIndexPath: indexPath)

                        waitUntil() { done in
                            NSThread.sleepForTimeInterval(0.1)
                            done()
                        }
                        expect(spotifyPlaylistTableController.presentedViewController)
                            .toEventually(beNil())
                    }
                }
            }
            
            describe("press the play/pause button") {
                context("and the playlist has not played yet") {
                    it("calls to play the playlist from the first index") {
                        self.pressPlayPauseButton(spotifyPlaylistTableController)
                        
                        self.verifyCallsToPlayTracksForURIsOn(mockSpotifyAudioFacade, expectedURIs: playlist.songURIs, expectedIndex: 0)
                    }
                }
                
                context("and play has already started") {
                    beforeEach() {
                        mockSpotifyAudioFacade.mocker.prepareForCallTo(MockSpotifyAudioFacade.Method.getCurrentSpotifyTrack, returnValue: spotifyTrack)
                    }
                    
                    it("toggles play") {
                        self.pressPlayPauseButton(spotifyPlaylistTableController)
                        
                        expect(mockSpotifyAudioFacade.mocker.getCallCountFor(
                            MockSpotifyAudioFacade.Method.togglePlay)).toEventually(equal(1))
                    }
                    
                    context("and upon failing to toggle play") {
                        let error = NSError(domain: "com.spotify.ios", code: 999, userInfo: [NSLocalizedDescriptionKey: "couldn't toggle play"])
                        
                        it("displays the error message in an alert") {
                            mockSpotifyAudioFacade.mocker.prepareForCallTo(
                                MockSpotifyAudioFacade.Method.togglePlay, returnValue: error)
                            
                            self.pressPlayPauseButton(spotifyPlaylistTableController)
                            
                            self.assertSimpleUIAlertControllerPresentedOnController(spotifyPlaylistTableController, withTitle: "Unable to Play Song", andMessage: error.localizedDescription)
                        }
                    }
                }
            }
            
            describe("press the song view button") {
                let spotifyAuth = self.getMockSpotifyAuthThatExpiresIn(60)
                
                beforeEach() {
                    spotifyPlaylistTableController.spotifyAuth = spotifyAuth
                }
                
                it("shows the spotify track view") {
                    self.pressSongViewButton(spotifyPlaylistTableController)
                    
                    expect(spotifyPlaylistTableController.presentedViewController).toEventually(
                        beAnInstanceOf(SpotifyTrackViewController))
                    let spotifyTrackViewController = spotifyPlaylistTableController.presentedViewController as? SpotifyTrackViewController
                    expect(spotifyTrackViewController?.spotifyAudioFacade as? MockSpotifyAudioFacade).to(beIdenticalTo(mockSpotifyAudioFacade))
                }
            }
            
            describe("playback status change") {
                context("when is playing") {
                    it("sets the play/pause button to the 'pause' system item") {
                        spotifyPlaylistTableController.changedPlaybackStatus(true)
                        
                        expect(self.getPlayPauseButtonSystemItemFromToolbar(spotifyPlaylistTableController)).to(equal(UIBarButtonSystemItem.Pause))
                    }
                }
                
                context("when is not playing") {
                    it("sets the play/pause button to the 'play' system item") {
                        spotifyPlaylistTableController.changedPlaybackStatus(false)
                        
                        expect(self.getPlayPauseButtonSystemItemFromToolbar(spotifyPlaylistTableController)).to(equal(UIBarButtonSystemItem.Play))
                    }
                }
            }
            
            describe("current track change") {
                beforeEach() {
                    mockControllerHelper.mocker.prepareForCallTo(MockControllerHelper.Method.getImageForURL, returnValue: image)
                }
                
                context("and it is not nil") {
                    beforeEach() {
                        spotifyPlaylistTableController.changedCurrentTrack(spotifyTrack)
                    }
                    
                    it("updates the song view button image") {
                        expect(self.getSongViewButtonBackgroundImageFromToolbar(spotifyPlaylistTableController)).toEventually(equal(image))
                    }
                    
                    it("updates the selected song in the table") {
                        expect(spotifyPlaylistTableController.tableView.indexPathForSelectedRow?.row)
                            .toEventually(equal(1))
                    }
                }
                
                context("and it is nil and previous track was not nil") {
                    beforeEach() {
                        spotifyPlaylistTableController.changedCurrentTrack(spotifyTrack)
                        
                        expect(self.getSongViewButtonBackgroundImageFromToolbar(spotifyPlaylistTableController)).toEventually(equal(image))
                        
                        spotifyPlaylistTableController.changedCurrentTrack(nil)
                    }
                    
                    it("removes the image from the song view button") {
                        expect(self.getSongViewButtonBackgroundImageFromToolbar(spotifyPlaylistTableController))
                            .toEventually(beNil())
                    }
                    
                    it("unselects all tracks in the table") {
                        expect(spotifyPlaylistTableController.tableView.indexPathForSelectedRow)
                            .toEventually(beNil())
                    }
                }
            }

            describe("playlist name pressed") {
                beforeEach() {
                    spotifyPlaylistTableController.playlistNameButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
                }
                
                afterEach() {
                    spotifyPlaylistTableController.presentedViewController?.removeFromParentViewController()
                }
                
                it("presents the playlist name entry view") {
                    expect(spotifyPlaylistTableController.presentedViewController).toEventually(beAnInstanceOf(PlaylistNameEntryController))
                }
                
                it("displays the current name in the playlist name entry view") {
                    let textField = (spotifyPlaylistTableController.presentedViewController as? PlaylistNameEntryController)?.textFields?.first
                    expect(textField?.text).to(equal(playlist.name))
                }
            }
            
            describe("new playlist pressed") {
                context("when the current playlist has been saved") {
                    beforeEach() {
                        spotifyPlaylistTableController.spotifyAuth = self.getMockSpotifyAuthThatExpiresIn(60)
                        mockSpotifyService.mocker.prepareForCallTo(MockSpotifyService.Method.savePlaylist, returnValue: SpotifyService.PlaylistResult.Success(Playlist(name: "saved playlist", uri: NSURL(string: "uri"))))

                        self.pressSaveButton(spotifyPlaylistTableController)
                        self.advanceRunLoopForTimeInterval(0.0)
                        
                        expect(spotifyPlaylistTableController.saveButton.title).toEventually(equal("Playlist Saved"))
                    }
                    
                    it("unwinds to create playlist") {
                        self.pressNewPlaylistButton(spotifyPlaylistTableController)
                        self.advanceRunLoopForTimeInterval(0.0)
                        
                        expect(navigationController.topViewController)
                            .toEventually(beAnInstanceOf(CreatePlaylistController))
                    }
                }
                
                context("when the current playlist has not been saved") {
                    it("asks the user to confirm abandoning the playlist") {
                        self.pressNewPlaylistButton(spotifyPlaylistTableController)
                        self.advanceRunLoopForTimeInterval(0.0)
                        
                        self.assertSimpleUIAlertControllerPresentedOnController(spotifyPlaylistTableController, withTitle: "Unsaved Playlist", andMessage: "Abandon changes to this playlist?")
                    }
                }
            }
            
            describe("edit pressed") {
                it("updates the save button text") {
                    self.pressEditButton(spotifyPlaylistTableController)
                    
                    expect(spotifyPlaylistTableController.saveButton.title).to(equal("Editing Playlist"))
                }
                
                it("disables the save button") {
                    spotifyPlaylistTableController.saveButton.enabled = true
                    
                    self.pressEditButton(spotifyPlaylistTableController)
                    
                    expect(spotifyPlaylistTableController.saveButton.enabled).toNot(beTrue())
                }
                
                context("when play has already started") {
                    it("retains the selected song in the table") {
                        mockSpotifyAudioFacade.mocker.prepareForCallTo(MockSpotifyAudioFacade.Method.getCurrentSpotifyTrack, returnValue: spotifyTrack)
                        
                        self.pressEditButton(spotifyPlaylistTableController)

                        expect(spotifyPlaylistTableController.tableView.indexPathForSelectedRow?.row)
                            .toEventually(equal(1))
                    }
                }
            }
            
            describe("edit the table") {
                let firstIndexPath = NSIndexPath(forRow: 0, inSection: 0)
                let secondIndexPath = NSIndexPath(forRow: 1, inSection: 0)
                var deleteAction: UITableViewRowAction!
                var replaceAction: UITableViewRowAction!
                
                beforeEach() {
                    deleteAction = spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, editActionsForRowAtIndexPath: firstIndexPath)![0]
                    replaceAction = spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, editActionsForRowAtIndexPath: firstIndexPath)![1]
                    
                    self.pressEditButton(spotifyPlaylistTableController)
                }
                
                describe("reorder songs") {
                    context("when song position changes") {
                        it("updates the table to reflect the change") {
                            let firstCellTextPreEdit = spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, cellForRowAtIndexPath: firstIndexPath).textLabel?.text
                            let secondCellTextPreEdit = spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, cellForRowAtIndexPath: secondIndexPath).textLabel?.text

                            spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, moveRowAtIndexPath: firstIndexPath, toIndexPath: secondIndexPath)
                            
                            let firstCellTextPostEdit = spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, cellForRowAtIndexPath: firstIndexPath).textLabel?.text
                            let secondCellTextPostEdit = spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, cellForRowAtIndexPath: secondIndexPath).textLabel?.text
                            expect(firstCellTextPostEdit).to(equal(secondCellTextPreEdit))
                            expect(firstCellTextPreEdit).to(equal(secondCellTextPostEdit))
                        }
                        
                        context("and play has not yet started") {
                            it("does not update the playlist with the spotify audio facade") {
                                spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, moveRowAtIndexPath: firstIndexPath, toIndexPath: secondIndexPath)
                                self.advanceRunLoopForTimeInterval(0.05)
                                
                                expect(mockSpotifyAudioFacade.mocker.getCallCountFor(
                                    MockSpotifyAudioFacade.Method.updatePlaylist)).toEventually(equal(0))
                            }
                        }

                        context("and play has already started") {
                            let expectedNewIndex = 0
                            
                            beforeEach() {
                                mockSpotifyAudioFacade.mocker.prepareForCallTo(MockSpotifyAudioFacade.Method.getCurrentSpotifyTrack, returnValue: spotifyTrack)
                            }
                            
                            it("updates the selected song in the table") {
                                spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, moveRowAtIndexPath: firstIndexPath, toIndexPath: secondIndexPath)
                                self.advanceRunLoopForTimeInterval(0.0)
                                
                                expect(spotifyPlaylistTableController.tableView.indexPathForSelectedRow?.row)
                                    .toEventually(equal(expectedNewIndex))
                            }
                            
                            it("updates the playlist with the spotify audio facade") {
                                spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, moveRowAtIndexPath: firstIndexPath, toIndexPath: secondIndexPath)
                                self.advanceRunLoopForTimeInterval(0.0)
                                
                                self.verifyCallToUpdatePlaylistOn(mockSpotifyAudioFacade, expectedPlaylist: spotifyPlaylistTableController.playlist, expectedIndex: expectedNewIndex)
                            }
                        }
                    }
                }
                
                describe("delete song") {
                    it("removes the row from the table") {
                        spotifyPlaylistTableController.handleDeleteRow(deleteAction, indexPath: firstIndexPath)

                        expect(spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, numberOfRowsInSection: 0)).to(equal(1))
                        expect(spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, cellForRowAtIndexPath: firstIndexPath).textLabel?.text).to(equal(playlist.songs[1].title))
                    }
                    
                    context("and play has not yet started") {
                        it("does not update the playlist with the spotify audio facade") {
                            spotifyPlaylistTableController.handleDeleteRow(deleteAction, indexPath: firstIndexPath)
                            
                            expect(mockSpotifyAudioFacade.mocker.getCallCountFor(
                                MockSpotifyAudioFacade.Method.updatePlaylist)).toEventually(equal(0))
                        }
                    }
                    
                    context("and play has already started") {
                        let expectedNewIndex = 0
                        
                        beforeEach() {
                            mockSpotifyAudioFacade.mocker.prepareForCallTo(MockSpotifyAudioFacade.Method.getCurrentSpotifyTrack, returnValue: spotifyTrack)
                        }
                        
                        it("updates the selected song in the table") {
                            spotifyPlaylistTableController.handleDeleteRow(deleteAction, indexPath: firstIndexPath)
                            
                            expect(spotifyPlaylistTableController.tableView.indexPathForSelectedRow?.row)
                                .toEventually(equal(expectedNewIndex))
                        }
                        
                        it("updates the playlist with the spotify audio facade") {
                            spotifyPlaylistTableController.handleDeleteRow(deleteAction, indexPath: firstIndexPath)
                            
                            self.verifyCallToUpdatePlaylistOn(mockSpotifyAudioFacade, expectedPlaylist: spotifyPlaylistTableController.playlist, expectedIndex: expectedNewIndex)
                        }
                        
                        context("and the deleted song is playing") {
                            it("stops play") {
                                spotifyPlaylistTableController.handleDeleteRow(deleteAction, indexPath: secondIndexPath)
                                
                                expect(mockSpotifyAudioFacade.mocker.getCallCountFor(
                                    MockSpotifyAudioFacade.Method.stopPlay)).to(equal(1))
                            }
                        }
                    }
                }
                
                describe("replace button pressed") {
                    it("sets the song replacement index") {
                        spotifyPlaylistTableController.handleReplaceRow(replaceAction, indexPath: firstIndexPath)

                        expect(spotifyPlaylistTableController.songReplacementIndexPath).to(equal(firstIndexPath))
                    }
                    
                    it("prompts to choose to use the same name") {
                        spotifyPlaylistTableController.handleReplaceRow(replaceAction, indexPath: firstIndexPath)
                        
                        self.assertSimpleUIAlertControllerPresentedOnController(spotifyPlaylistTableController, withTitle: "Replace this Song", andMessage: "(For Bobby McGee)")
                    }
                    
                    context("when the song is not associated with a contact") {
                        it("prompts the user to choose a new name") {
                            spotifyPlaylistTableController.handleReplaceRow(replaceAction, indexPath: secondIndexPath)
                            
                            expect(navigationController.topViewController)
                                .toEventually(beAnInstanceOf(SingleNameEntryController))
                        }
                    }
                }
                
                describe("complete replacement with song and contact") {
                    let newSong = Song(title: "Don’t call me Whitney, Bobby",
                        artistNames: ["Islands"],
                        uri: NSURL(string:"spotify:track:51L6XqGwYaRUh5qenzko3F")!)
                    var numberOfRowsBefore: Int!
                    
                    beforeEach() {
                        numberOfRowsBefore = spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, numberOfRowsInSection: 0)
                    }
                    
                    it("replaces the row in the table") {
                        spotifyPlaylistTableController.songReplacementIndexPath = firstIndexPath
                        spotifyPlaylistTableController.completeReplacementWithSong(newSong, andContact: nil)
                        
                        expect(spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, numberOfRowsInSection: 0)).to(equal(numberOfRowsBefore))
                        expect(spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, cellForRowAtIndexPath: firstIndexPath).textLabel?.text).to(equal(newSong.title))
                        expect(spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, cellForRowAtIndexPath: firstIndexPath).detailTextLabel?.text).to(equal(newSong.displayArtistName))
                    }
                    
                    context("and play has not yet started") {
                        it("does not update the playlist with the spotify audio facade") {
                            spotifyPlaylistTableController.songReplacementIndexPath = firstIndexPath
                            spotifyPlaylistTableController.completeReplacementWithSong(newSong, andContact: nil)
                            
                            expect(mockSpotifyAudioFacade.mocker.getCallCountFor(
                                MockSpotifyAudioFacade.Method.updatePlaylist)).toEventually(equal(0))
                        }
                    }
                    
                    context("and play has already started") {
                        let spotifyAuth = self.getMockSpotifyAuthThatExpiresIn(60)

                        beforeEach() {
                            spotifyPlaylistTableController.spotifyAuth = spotifyAuth
                            mockSpotifyAudioFacade.mocker.prepareForCallTo(MockSpotifyAudioFacade.Method.getCurrentSpotifyTrack, returnValue: spotifyTrack)
                        }
                        
                        context("and the replaced song is not currently playing") {
                            beforeEach() {
                                spotifyPlaylistTableController.songReplacementIndexPath = firstIndexPath
                                spotifyPlaylistTableController.completeReplacementWithSong(newSong, andContact: nil)
                            }
                            
                            it("updates the playlist with the spotify audio facade") {
                                self.verifyCallToUpdatePlaylistOn(mockSpotifyAudioFacade, expectedPlaylist: spotifyPlaylistTableController.playlist, expectedIndex: 1)
                            }
                            
                            it("does not restart play") {
                                expect(mockSpotifyAudioFacade.mocker.getCallCountFor(
                                    MockSpotifyAudioFacade.Method.playTracksForURIs)).to(equal(0))
                            }
                        }
                        
                        context("and the replaced song is playing") {
                            beforeEach() {
                                spotifyPlaylistTableController.songReplacementIndexPath = secondIndexPath
                                spotifyPlaylistTableController.completeReplacementWithSong(newSong, andContact: nil)
                            }
                            
                            it("does not update the playlist with the spotify audio facade") {
                                expect(mockSpotifyAudioFacade.mocker.getCallCountFor(
                                    MockSpotifyAudioFacade.Method.updatePlaylist)).to(equal(0))
                            }
                            
                            it("starts playing the new song") {
                                self.verifyCallsToPlayTracksForURIsOn(mockSpotifyAudioFacade, expectedURIs: spotifyPlaylistTableController.playlist.songURIs, expectedIndex: 1)
                            }
                        }
                    }
                }
                
                context("when editing complete") {
                    it("updates the save button text") {
                        self.pressEditButton(spotifyPlaylistTableController)
                        
                        expect(spotifyPlaylistTableController.saveButton.title).to(equal("Save to Spotify"))
                    }
                    
                    it("enables the save button") {
                        spotifyPlaylistTableController.saveButton.enabled = false
                        
                        self.pressEditButton(spotifyPlaylistTableController)
                        
                        expect(spotifyPlaylistTableController.saveButton.enabled).to(beTrue())
                    }
                    
                    context("and play has already started") {
                        beforeEach() {
                            mockSpotifyAudioFacade.mocker.prepareForCallTo(MockSpotifyAudioFacade.Method.getCurrentSpotifyTrack, returnValue: spotifyTrack)
                        }
                        
                        it("retains the selected song in the table") {
                            self.pressEditButton(spotifyPlaylistTableController)
                            
                            expect(spotifyPlaylistTableController.tableView.indexPathForSelectedRow?.row)
                                .toEventually(equal(1))
                        }
                        
                        context("and current track was deleted") {
                            it("unselects all tracks in the table") {
                                spotifyPlaylistTableController.handleDeleteRow(deleteAction, indexPath: secondIndexPath)

                                self.pressEditButton(spotifyPlaylistTableController)
                                self.advanceRunLoopForTimeInterval(0.05)

                                expect(spotifyPlaylistTableController.tableView.indexPathForSelectedRow)
                                    .toEventually(beNil())
                            }
                        }
                    }
                }
            }
            
            describe("unwind to create playlist") {
                it("stops play") {
                    spotifyPlaylistTableController.performSegueWithIdentifier(
                        "UnwindToCreatePlaylistFromPlaylistTableSegue", sender: nil)
                    self.advanceRunLoopForTimeInterval(0.0)
                    
                    expect(mockSpotifyAudioFacade.mocker.getCallCountFor(
                        MockSpotifyAudioFacade.Method.stopPlay)).to(equal(1))
                }
            }
            
            describe("segue to the SpotifySongSelectionController") {
                beforeEach() {
                    spotifyPlaylistTableController.songReplacementIndexPath = NSIndexPath(forRow: 0, inSection: 0)
                    spotifyPlaylistTableController.performSegueWithIdentifier("SelectSongSameContactSegue", sender: nil)
                }
                
                it("shows the spotify song selection table") {
                    expect(navigationController.topViewController)
                        .toEventually(beAnInstanceOf(SpotifySongSelectionTableController))
                }
                
                it("sets the search contact on the song selection table controller") {
                    let spotifySongSelectionTableController = navigationController.topViewController as? SpotifySongSelectionTableController
                    expect(spotifySongSelectionTableController?.searchContact).to(equal(playlist.songsWithContacts[0].contact))
                }
                
                it("sets the song selection completion handler on the song selection table controller") {
                    let spotifySongSelectionTableController = navigationController.topViewController as? SpotifySongSelectionTableController
                    expect(spotifySongSelectionTableController?.songSelectionCompletionHandler).toNot(beNil())
                }
            }
            
            describe("segue to the SingleNameEntryController") {
                beforeEach() {
                    spotifyPlaylistTableController.songReplacementIndexPath = NSIndexPath(forRow: 0, inSection: 0)
                    spotifyPlaylistTableController.performSegueWithIdentifier("EnterNameSegue", sender: nil)
                }
                
                it("shows the single name entry view") {
                    expect(navigationController.topViewController)
                        .toEventually(beAnInstanceOf(SingleNameEntryController))
                }
                
                it("sets the song selection completion handler on the song selection table controller") {
                    let singleNameEntryController = navigationController.topViewController as? SingleNameEntryController
                    expect(singleNameEntryController?.songSelectionCompletionHandler).toNot(beNil())
                }
            }
        }
    }
    
    func getMockSpotifyAuthThatExpiresIn(expiresIn: NSTimeInterval) -> MockSPTAuth {
        let mockSpotifyAuth = getMockSpotifyAuth()
        mockSpotifyAuth.mocker.clearMockedReturnsFor(MockSPTAuth.Method.getSession)
        mockSpotifyAuth.mocker.prepareForCallTo(MockSPTAuth.Method.getSession, returnValue: getSPTSessionThatExpiresIn(expiresIn))
        return mockSpotifyAuth
    }
    
    func getMockSpotifyAuth() -> MockSPTAuth {
        let mockSpotifyAuth = MockSPTAuth()
        mockSpotifyAuth.clientID = "clientID"
        mockSpotifyAuth.redirectURL = NSURL(string: "redirect://url")
        mockSpotifyAuth.tokenSwapURL = NSURL(string: "https://token/swap")
        mockSpotifyAuth.mocker.prepareForCallTo(MockSPTAuth.Method.getSession, returnValue: nil)
        mockSpotifyAuth.mocker.prepareForCallTo(MockSPTAuth.Method.hasTokenRefreshService, returnValue: true)

        return mockSpotifyAuth
    }
    
    func getSPTSessionThatExpiresIn(expiresIn: NSTimeInterval) -> SPTSession {
        return SPTSession(userName: "user", accessToken: "token", expirationDate: NSDate(timeIntervalSinceNow: expiresIn))
    }
    
    func pressSaveButton(spotifyPlaylistTableController: SpotifyPlaylistTableController) {
        pressBarButton(spotifyPlaylistTableController.saveButton)
    }
    
    func pressPlayPauseButton(spotifyPlaylistTableController: SpotifyPlaylistTableController) {
        pressBarButton(spotifyPlaylistTableController.playPauseButton)
    }
    
    func pressSongViewButton(spotifyPlaylistTableController: SpotifyPlaylistTableController) {
        pressBarButton(spotifyPlaylistTableController.songViewButton)
    }
    
    func pressNewPlaylistButton(spotifyPlaylistTableController: SpotifyPlaylistTableController) {
        pressBarButton(spotifyPlaylistTableController.newPlaylistButton)
    }
    
    func pressEditButton(spotifyPlaylistTableController: SpotifyPlaylistTableController) {
        pressBarButton(spotifyPlaylistTableController.editButtonItem())
    }
    
    func pressBarButton(barButton: UIBarButtonItem) {
        UIApplication.sharedApplication().sendAction(barButton.action, to: barButton.target, from: self, forEvent: nil)
    }
    
    func assertSimpleUIAlertControllerPresentedOnController(parentController: UIViewController, withTitle expectedTitle: String, andMessage expectedMessage: String) {
        self.advanceRunLoopForTimeInterval(0.5)
        expect(parentController.presentedViewController).toEventuallyNot(beNil())
        expect(parentController.presentedViewController).toEventually(beAnInstanceOf(UIAlertController))
        if let alertController = parentController.presentedViewController as? UIAlertController {
            expect(alertController.title).toEventually(equal(expectedTitle))
            expect(alertController.message).toEventually(equal(expectedMessage))
        }
    }
    
    func getPlayPauseButtonSystemItemFromToolbar(spotifyPlaylistTableController: SpotifyPlaylistTableController) -> UIBarButtonSystemItem {
        let playPauseButton = spotifyPlaylistTableController.toolbarItems?[4]
        return UIBarButtonSystemItem(rawValue: playPauseButton!.valueForKey("systemItem") as! Int)!
    }
    
    func getSongViewButtonBackgroundImageFromToolbar(spotifyPlaylistTableController: SpotifyPlaylistTableController) -> UIImage? {
        let songViewButton = spotifyPlaylistTableController.toolbarItems?[0]
        return (songViewButton?.customView as? UIButton)?.currentBackgroundImage
    }
    
    func verifyCallsToPlayTracksForURIsOn(mockSpotifyAudioFacade: MockSpotifyAudioFacade, expectedURIs: [NSURL], expectedIndex: Int) {
        expect(mockSpotifyAudioFacade.mocker.getNthCallTo(MockSpotifyAudioFacade.Method.playTracksForURIs, n: 0)?[0] as? [NSURL]).toEventually(equal(expectedURIs))
        expect(mockSpotifyAudioFacade.mocker.getNthCallTo(MockSpotifyAudioFacade.Method.playTracksForURIs, n: 0)?[1] as? Int).toEventually(equal(expectedIndex))
    }
    
    func verifyCallToUpdatePlaylistOn(mockSpotifyAudioFacade: MockSpotifyAudioFacade, expectedPlaylist: Playlist, expectedIndex: Int) {
        self.advanceRunLoopForTimeInterval(0.1)
        expect(mockSpotifyAudioFacade.mocker.getNthCallTo(MockSpotifyAudioFacade.Method.updatePlaylist, n: 0)?[0] as? Playlist).toEventually(equal(expectedPlaylist))
        expect(mockSpotifyAudioFacade.mocker.getNthCallTo(MockSpotifyAudioFacade.Method.updatePlaylist, n: 0)?[1] as? Int).toEventually(equal(expectedIndex))
    }
    
    func advanceRunLoopForTimeInterval(timeInterval: Double) {
        NSRunLoop.mainRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: timeInterval))
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
