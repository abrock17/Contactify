import TuneThatName
import Quick
import Nimble

class SpotifyTrackViewControllerSpec: QuickSpec {
    
    override func spec() {
        describe("SpotifyTrackViewController") {
            let spotifyTrack = SpotifyTrack(
                uri: NSURL(string: "spotify:track:1TYlZJWUNAJFXeF8FbPRIp")!,
                name: "Springfield, Or Bobby Got A Shadfly Caught In His Hair",
                artistNames: ["Sufjan Stevens"],
                albumName: "The Avalanche",
                albumLargestCoverImageURL: NSURL(string: "https://i.scdn.co/image/eecb04997c5c163e2fc73804cc169fa46e87666e")!,
                albumSmallestCoverImageURL: NSURL(string: "https://i.scdn.co/image/9fc8918a40a16e51eab4dd97512d623c2b590c63")!)
            let image = UIImage(named: "yuck.png", inBundle: NSBundle(forClass: SpotifyPlaylistTableControllerSpec.self), compatibleWithTraitCollection: nil)

            var spotifyTrackViewController: SpotifyTrackViewController!
            var navigationController: UINavigationController!
            var mockSpotifyAudioFacade: MockSpotifyAudioFacade!
            var mockControllerHelper: MockControllerHelper!

            beforeEach() {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                
                navigationController = storyboard.instantiateInitialViewController() as! UINavigationController
                
                spotifyTrackViewController = storyboard.instantiateViewControllerWithIdentifier("SpotifyTrackViewController") as!  SpotifyTrackViewController
                
                mockSpotifyAudioFacade = MockSpotifyAudioFacade()
                spotifyTrackViewController.spotifyAudioFacade = mockSpotifyAudioFacade
                mockControllerHelper = MockControllerHelper()
                spotifyTrackViewController.controllerHelper = mockControllerHelper
                
                mockSpotifyAudioFacade.mocker.prepareForCallTo(MockSpotifyAudioFacade.Method.getCurrentSpotifyTrack, returnValue: spotifyTrack)
                mockControllerHelper.mocker.prepareForCallTo(MockControllerHelper.Method.getImageForURL, returnValue: image)
                
                navigationController.pushViewController(spotifyTrackViewController, animated: false)
                UIApplication.sharedApplication().keyWindow!.rootViewController = navigationController
                NSRunLoop.mainRunLoop().runUntilDate(NSDate())
            }
            
            it("sets itself as the playback delegate on the spotifyAudioFacade") {
                expect(mockSpotifyAudioFacade.mocker.getNthCallTo(MockSpotifyAudioFacade.Method.setPlaybackDelegate, n: 0)?.first as? SpotifyTrackViewController).to(beIdenticalTo(spotifyTrackViewController))
            }
            
            it("sets the title, artist, and album label text for the current spotify track") {
                self.verifyLabelTextOnSpotifyTrackViewController(spotifyTrackViewController, forSpotifyTrack: spotifyTrack)
            }
            
            it("sets the album cover image for the current spotify track") {
                expect(spotifyTrackViewController.albumImageView.image).toEventually(equal(image))
            }
            
            describe("starts playing spotify track") {
                let newSpotifyTrack = SpotifyTrack(
                    uri: NSURL(string: "spotify:track:453d5sjBIPAfhajumXOPIs")!,
                    name: "Thunderclap For Bobby Pyn",
                    artistNames: ["Sonic Youth"],
                    albumName: "The Eternal",
                    albumLargestCoverImageURL: NSURL(string: "https://i.scdn.co/image/69f66e5ed0071a7c09705145e5bc7baf8a389499")!,
                    albumSmallestCoverImageURL: NSURL(string: "https://i.scdn.co/image/8775b33d7423ca4281f1be7477f5a7e1ca3ce588")!)
                beforeEach() {
                    spotifyTrackViewController.albumImageView.image = nil
                    
                    spotifyTrackViewController.startedPlayingSpotifyTrack(newSpotifyTrack)
                }
                
                it("updates the title, artist, and album label text for the spotify track") {
                    self.verifyLabelTextOnSpotifyTrackViewController(spotifyTrackViewController, forSpotifyTrack: newSpotifyTrack)
                }
                
                it("updates the album cover image for the spotify track") {
                    expect(spotifyTrackViewController.albumImageView.image).toEventually(equal(image))
                }
            }
        }
    }
    
    func verifyLabelTextOnSpotifyTrackViewController(spotifyTrackViewController: SpotifyTrackViewController, forSpotifyTrack spotifyTrack: SpotifyTrack) {
        expect(spotifyTrackViewController.titleLabel.text).to(equal(spotifyTrack.name))
        expect(spotifyTrackViewController.artistLabel.text).to(equal(spotifyTrack.displayArtistName))
        expect(spotifyTrackViewController.albumLabel.text).to(equal(spotifyTrack.albumName))
    }
}
