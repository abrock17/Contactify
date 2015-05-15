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
//                let playlistTableViewController = navigationController.childViewControllers[1] as! PlaylistTableViewController
//                playlistTableViewController.spotifyAudioFacade = MockSpotifyAudioFacade()
                
                mockPlaylistService = MockPlaylistService()
                createPlaylistController.playlistService = mockPlaylistService
                
                UIApplication.sharedApplication().keyWindow!.rootViewController = navigationController
                createPlaylistController.loadView()
            }

            describe("press the create playlist button") {
                context("when the playlist service calls back with an error") {
                    let expectedError = NSError(domain: "domain", code: 435, userInfo: [NSLocalizedDescriptionKey: "an error description"])
                    beforeEach() {
                        mockPlaylistService.mocker.prepareForCallTo(MockPlaylistService.Method.createPlaylist, returnValue: PlaylistService.PlaylistResult.Failure(expectedError))
                        
                        createPlaylistController.createPlaylistButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
                    }
                    
                    it("does not segue to the playlist table view") {
                        expect(navigationController.topViewController).toEventuallyNot(beAnInstanceOf(PlaylistTableViewController))
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
                        expect(navigationController.topViewController).toEventually(beAnInstanceOf(PlaylistTableViewController))
                        let playlistTableViewController = navigationController.topViewController as! PlaylistTableViewController
                        expect(playlistTableViewController.playlist).to(equal(expectedPlaylist))
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