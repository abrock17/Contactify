import UIKit

public class SpotifyTrackViewController: UIViewController, SpotifyPlaybackDelegate {
    
    public var spotifyAudioFacade: SpotifyAudioFacade!
    public var controllerHelper = ControllerHelper()
    
    @IBOutlet public weak var albumImageView: UIImageView!
    @IBOutlet public weak var titleLabel: UILabel!
    @IBOutlet public weak var artistLabel: UILabel!
    @IBOutlet public weak var albumLabel: UILabel!
    @IBOutlet public weak var closeButton: UIBarButtonItem!

    public override func viewDidLoad() {
        super.viewDidLoad()
    }

    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        spotifyAudioFacade.playbackDelegate = self
        startedPlayingSpotifyTrack(spotifyAudioFacade.currentSpotifyTrack)
    }
    
    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    public func changedPlaybackStatus(isPlaying: Bool) {
    }
    
    public func startedPlayingSpotifyTrack(spotifyTrack: SpotifyTrack?) {
        titleLabel.text = spotifyTrack?.name
        artistLabel.text = spotifyTrack?.displayArtistName
        albumLabel.text = spotifyTrack?.albumName
        if spotifyTrack?.albumLargestCoverImageURL != nil {
            controllerHelper.getImageForURL(spotifyTrack!.albumLargestCoverImageURL) {
                image in
                
                self.albumImageView.image = image
            }
        }
    }
}
