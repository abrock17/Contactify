import TuneThatName
import Quick
import Nimble
import UIKit

class CreatePlaylistControllerSpec: QuickSpec {
    
    override func spec() {
        describe("The CreatePlaylistController") {
            var navigationController: UINavigationController!
            var createPlaylistController: CreatePlaylistController!
            var mockPlaylistService: MockPlaylistService!
            
            beforeEach() {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                navigationController = storyboard.instantiateInitialViewController() as! UINavigationController
                createPlaylistController = navigationController.childViewControllers.first as! CreatePlaylistController
                
                mockPlaylistService = MockPlaylistService()
                createPlaylistController.playlistService = mockPlaylistService

                UIApplication.sharedApplication().keyWindow!.rootViewController = navigationController
                NSRunLoop.mainRunLoop().runUntilDate(NSDate())
                createPlaylistController.viewDidLoad()
            }
            
            describe("number of songs slider") {
                it("has the correct initial value") {
                    expect(createPlaylistController.numberOfSongsSlider.value).to(beCloseTo(0.0909, within: 0.0001))
                }
            }
            
            describe("number of songs label") {
                it("has the correct initial text") {
                    expect(createPlaylistController.numberOfSongsLabel.text).to(equal("10"))
                }
            }
            
            describe("favor popular songs switch") {
                it("has the correct initial state") {
                    expect(createPlaylistController.favorPopularSwitch.on).to(beTrue())
                }
            }
            
            describe("number of songs slider value change") {
                context("when value changes") {
                    it("updates the number of songs label accordingly") {
                        createPlaylistController.numberOfSongsSlider.value = 1
                        createPlaylistController.numberOfSongsValueChanged(createPlaylistController.numberOfSongsSlider)
                        
                        expect(createPlaylistController.numberOfSongsLabel.text).to(equal("100"))
                    }
                }
            }
            
            describe("favor popular songs switch state change") {
                context("when state changes") {
                    it("updates the favor popular flag") {
                        createPlaylistController.favorPopularSwitch.on = false
                        createPlaylistController.favorPopularStateChanged(createPlaylistController.favorPopularSwitch)
                        
                        createPlaylistController.createPlaylistButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
                        expect((mockPlaylistService.mocker.getNthCallTo(MockPlaylistService.Method.createPlaylist, n: 0)?[1] as? SongPreferences)?.favorPopular).toEventually(beFalse())
                    }
                }
            }

            describe("press the create playlist button") {
                it("calls the playlist service with the correct number of songs") {
                    createPlaylistController.createPlaylistButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)

                    expect(mockPlaylistService.mocker.getNthCallTo(MockPlaylistService.Method.createPlaylist, n: 0)?.first as? Int).toEventually(equal(10))
                }
                
                context("when the playlist service calls back with an error") {
                    let expectedError = NSError(domain: "domain", code: 435, userInfo: [NSLocalizedDescriptionKey: "an error description"])
                    beforeEach() {
                        mockPlaylistService.mocker.prepareForCallTo(MockPlaylistService.Method.createPlaylist, returnValue: PlaylistService.PlaylistResult.Failure(expectedError))
                        
                        createPlaylistController.createPlaylistButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
                    }
                    
                    it("does not segue to the playlist table view") {
                        expect(navigationController.topViewController).toEventuallyNot(beAnInstanceOf(SpotifyPlaylistTableController))
                    }

                    it("displays the error message in an alert") {
                        expect(createPlaylistController.presentedViewController).toEventuallyNot(beNil())
                        expect(createPlaylistController.presentedViewController).toEventually(beAnInstanceOf(UIAlertController))
                        let alertController = createPlaylistController.presentedViewController as! UIAlertController
                        expect(alertController.title).toEventually(equal("Unable to Create Your Playlist"))
                        expect(alertController.message).toEventually(equal((expectedError.userInfo![NSLocalizedDescriptionKey] as! String)))
                    }
                }
                
                context("when the playlist service calls back with a playlist") {
                    let expectedPlaylist = Playlist(name: "playlist")
                    beforeEach() {
                        mockPlaylistService.mocker.prepareForCallTo(MockPlaylistService.Method.createPlaylist, returnValue: PlaylistService.PlaylistResult.Success(expectedPlaylist))
                        
                        createPlaylistController.createPlaylistButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
                        NSRunLoop.mainRunLoop().runUntilDate(NSDate())
                    }
                    
                    it("segues to the playlist table view passing the playlist") {
                        expect(navigationController.topViewController).toEventually(beAnInstanceOf(SpotifyPlaylistTableController))
                        let spotifyPlaylistTableController = navigationController.topViewController as? SpotifyPlaylistTableController
                        expect(spotifyPlaylistTableController?.playlist).to(equal(expectedPlaylist))
                    }
                }
            }
        }
    }
}

class MockPlaylistService: PlaylistService {
    
    let mocker = Mocker()
    
    struct Method {
        static let createPlaylist = "createPlaylist"
    }
    
    override func createPlaylist(#numberOfSongs: Int, songPreferences: SongPreferences, callback: PlaylistService.PlaylistResult -> Void) {
        mocker.recordCall(Method.createPlaylist, parameters: numberOfSongs, songPreferences)
        let mockedResult = mocker.returnValueForCallTo(Method.createPlaylist)
        if let mockedResult = mockedResult as? PlaylistService.PlaylistResult {
            callback(mockedResult)
        } else {
            callback(.Success(Playlist(name: "unimportant mocked playlist")))
        }
    }
}