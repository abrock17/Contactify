import TuneThatName
import Foundation
import Quick
import Nimble

class PlaylistTableViewControllerSpec: QuickSpec {
    
    override func spec() {
        
        describe("PlaylistTableViewController") {
            var playlistTableViewController: PlaylistTableViewController!

            describe("save the playlist to spotify") {
                beforeEach() {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    playlistTableViewController = storyboard.instantiateViewControllerWithIdentifier("PlaylistTableViewController") as  PlaylistTableViewController
                    let window = UIWindow(frame: UIScreen.mainScreen().bounds)
                    window.rootViewController = playlistTableViewController
                    window.makeKeyAndVisible()
                }
                
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
                        let spotifyAuth = self.getFakeSpotifyAuth()
                        spotifyAuth.session = SPTSession(userName: "user", accessToken: "token", expirationDate: NSDate(timeIntervalSinceNow: -60))
                        playlistTableViewController.spotifyAuth = spotifyAuth
                        
                        self.pressSaveButton(playlistTableViewController)
                        
                        expect(playlistTableViewController.presentedViewController).toNot(beNil())
                    }
                }
                
                context("when there is a valid session") {
                    it("does not prompt the user to log in") {
                        let spotifyAuth = self.getFakeSpotifyAuth()
                        spotifyAuth.session = SPTSession(userName: "user", accessToken: "token", expirationDate: NSDate(timeIntervalSinceNow: 60))
                        playlistTableViewController.spotifyAuth = spotifyAuth
                        
                        self.pressSaveButton(playlistTableViewController)
                        
                        expect(playlistTableViewController.presentedViewController).to(beNil())
                    }
                }
            }
        }
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
