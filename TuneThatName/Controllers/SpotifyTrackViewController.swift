import UIKit

public class SpotifyTrackViewController: UIViewController, SpotifyPlaybackDelegate {
    
    let playbackErrorTitle = "Unable to Control Playback"
    
    public var spotifyAudioFacade: SpotifyAudioFacade!
    public var controllerHelper = ControllerHelper()
    public var hidePreviousAndNextTrackButtons = false

    @IBOutlet public weak var albumImageView: UIImageView!
    @IBOutlet public weak var titleLabel: UILabel!
    @IBOutlet public weak var artistLabel: UILabel!
    @IBOutlet public weak var albumLabel: UILabel!
    @IBOutlet public weak var toolbar: UIToolbar!
    @IBOutlet public weak var playPauseButton: UIBarButtonItem!
    @IBOutlet public weak var nextTrackButton: UIBarButtonItem!
    @IBOutlet public weak var previousTrackButton: UIBarButtonItem!
    @IBOutlet public weak var trackDataView: UIView!
    var albumImageActivityIndicator: UIActivityIndicatorView!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
    }

    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // adjust album frame to proper size since autolayout has not taken effect yet
        albumImageView.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.x, self.view.frame.width, self.view.frame.width)
        albumImageActivityIndicator = ControllerHelper.newActivityIndicatorForView(albumImageView)
        spotifyAudioFacade.playbackDelegate = self
        if hidePreviousAndNextTrackButtons {
            toolbar.items?.removeAtIndex(4)
            toolbar.items?.removeAtIndex(2)
        }
    }
    
    public override func viewDidLayoutSubviews() {
        addTrackDetailGradient()
    }
    
    func addTrackDetailGradient() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.whiteColor().CGColor, UIAppearanceManager.barBackground.CGColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = trackDataView.bounds
        trackDataView.layer.insertSublayer(gradientLayer, atIndex: 0)
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
        self.toolbar.items?.removeLast()
        self.toolbar.items?.append(ControllerHelper.createPlayPauseButtonForTarget(self, withAction: "playPausePressed:", andIsPlaying: isPlaying))
    }
    
    public func changedCurrentTrack(spotifyTrack: SpotifyTrack?) {
        if let spotifyTrack = spotifyTrack {
            updateViewElementsForSpotifyTrack(spotifyTrack)
        }
    }
    
    func updateViewElementsForSpotifyTrack(spotifyTrack: SpotifyTrack) {
        titleLabel.text = spotifyTrack.name
        artistLabel.text = spotifyTrack.displayArtistName
        albumLabel.text = spotifyTrack.albumName
        if spotifyTrack.albumLargestCoverImageURL != nil {
            ControllerHelper.handleBeginBackgroundActivityForView(albumImageView,
                activityIndicator: albumImageActivityIndicator)

            controllerHelper.getImageForURL(spotifyTrack.albumLargestCoverImageURL) {
                image in
                
                let facadeCurrentSpotifyTrack = self.spotifyAudioFacade.currentSpotifyTrack
                if spotifyTrack.albumLargestCoverImageURL == facadeCurrentSpotifyTrack?.albumLargestCoverImageURL {
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
    
    @IBAction func closePressed(sender: UIBarButtonItem) {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
}
