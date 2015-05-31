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
                    expect(createPlaylistController.numberOfSongsSlider.value).to(equal(0.1))
                }
            }
            
            describe("number of songs label") {
                it("has the correct initial text") {
                    expect(createPlaylistController.numberOfSongsLabel.text).to(equal("10"))
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

            describe("press the create playlist button") {
                it("calls the playlist service with the correct number of songs") {
                    createPlaylistController.createPlaylistButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)

                    expect(mockPlaylistService.mocker.getNthCallTo(MockPlaylistService.Method.createPlaylist, n: 0)?.first as? Int).toEventually(equal(10))
                    
                    self.mockSpotifyAudioFacadeAfterSegue(navigationController)
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
                        
                        self.mockSpotifyAudioFacadeAfterSegue(navigationController)
                    }
                }
            }
        }
    }
    
    /* 
    * doing this to keep from instantiating a real SPTAudioStreamingController
    * which causes errors elsewhere in the tests
    */
    func mockSpotifyAudioFacadeAfterSegue(navigationController: UINavigationController) {
        expect(navigationController.topViewController).toEventually(beAnInstanceOf(SpotifyPlaylistTableController))
        (navigationController.topViewController as? SpotifyPlaylistTableController)?.spotifyAudioFacadeOverride = MockSpotifyAudioFacade()
    }
}

class MockPlaylistService: PlaylistService {
    
    let mocker = Mocker()
    
    struct Method {
        static let createPlaylist = "createPlaylist"
    }
    
    override func createPlaylist(#numberOfSongs: Int, callback: PlaylistService.PlaylistResult -> Void) {
        mocker.recordCall(Method.createPlaylist, parameters: numberOfSongs)
        let mockedResult = mocker.returnValueForCallTo(Method.createPlaylist)
        if let mockedResult = mockedResult as? PlaylistService.PlaylistResult {
            callback(mockedResult)
        } else {
            callback(.Success(Playlist(name: "unimportant mocked playlist")))
        }
    }
}