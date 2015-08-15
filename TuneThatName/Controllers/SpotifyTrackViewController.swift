import UIKit

public class SpotifyTrackViewController: UIViewController, SpotifyPlaybackDelegate {
    
    let playbackErrorTitle = "Unable to Control Playback"
    
    public var spotifyAudioFacade: SpotifyAudioFacade!
    public var controllerHelper = ControllerHelper()


    @IBOutlet public weak var albumImageView: UIImageView!
    @IBOutlet public weak var titleLabel: UILabel!
    @IBOutlet public weak var artistLabel: UILabel!
    @IBOutlet public weak var albumLabel: UILabel!
    @IBOutlet public weak var toolbar: UIToolbar!
    @IBOutlet public weak var playPauseButton: UIBarButtonItem!
    @IBOutlet public weak var nextTrackButton: UIBarButtonItem!
    @IBOutlet public weak var previousTrackButton: UIBarButtonItem!
    var albumImageActivityIndicator: UIActivityIndicatorView!

    public override func viewDidLoad() {
        super.viewDidLoad()
    }

    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        spotifyAudioFacade.playbackDelegate = self
        albumImageActivityIndicator = ControllerHelper.newActivityIndicatorForView(albumImageView)
        
        if let spotifyTrack = spotifyAudioFacade.currentSpotifyTrack {
            updateViewElementsForSpotifyTrack(spotifyTrack)
        }
        changedPlaybackStatus(spotifyAudioFacade.isPlaying)
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
        updatePlayPauseButton(isPlaying)
    }
    
    func updatePlayPauseButton(isPlaying: Bool) {
        let buttonSystemItem = isPlaying ? UIBarButtonSystemItem.Pause : UIBarButtonSystemItem.Play
        let updatedButton = UIBarButtonItem(barButtonSystemItem: buttonSystemItem, target: self, action: "playPausePressed:")
        self.toolbar.items?.removeLast()
        self.toolbar.items?.append(updatedButton)
    }
    
    public func changedCurrentTrack(spotifyTrack: SpotifyTrack?) {
        if let spotifyTrack = spotifyTrack {
            updateViewElementsForSpotifyTrack(spotifyTrack)
        } else {
            performSegueWithIdentifier("unwindToSpotifyPlaylistTable:", sender: self)
        }
    }
    
    func updateViewElementsForSpotifyTrack(spotifyTrack: SpotifyTrack) {
        titleLabel.text = spotifyTrack.name
        artistLabel.text = spotifyTrack.displayArtistName
        albumLabel.text = spotifyTrack.albumName
        if spotifyTrack.albumLargestCoverImageURL != nil {
            albumImageActivityIndicator.frame = albumImageView.bounds
            ControllerHelper.handleBeginBackgroundActivityForView(albumImageView,
                activityIndicator: albumImageActivityIndicator)

            controllerHelper.getImageForURL(spotifyTrack.albumLargestCoverImageURL) {
                image in
                
                if spotifyTrack.albumLargestCoverImageURL == self.spotifyAudioFacade.currentSpotifyTrack?.albumLargestCoverImageURL {
                    self.albumImageView.image = image
                    ControllerHelper.handleCompleteBackgroundActivityForView(self.albumImageView,
                        activityIndicator: self.albumImageActivityIndicator)
                }
            }
        }
    }
    
    @IBAction func playPausePressed(sender: UIBarButtonItem) {
        spotifyAudioFacade.togglePlay() {
            error in
            if error != nil {
                ControllerHelper.displaySimpleAlertForTitle(self.playbackErrorTitle, andError: error, onController: self)
            }
        }
    }
    
    @IBAction func nextTrackButtonPressed(sender: UIBarButtonItem) {
        spotifyAudioFacade.toNextTrack() {
            error in
            if error != nil {
                ControllerHelper.displaySimpleAlertForTitle(self.playbackErrorTitle, andError: error, onController: self)
            }
        }
    }
    
    @IBAction func previousTrackButtonPressed(sender: UIBarButtonItem) {
        spotifyAudioFacade.toPreviousTrack() {
            error in
            if error != nil {
                ControllerHelper.displaySimpleAlertForTitle(self.playbackErrorTitle, andError: error, onController: self)
            }
        }
    }
}
