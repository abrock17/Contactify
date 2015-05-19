import UIKit

public class CreatePlaylistController: UIViewController {
    
    var playlist: Playlist?
    
    public var playlistService = PlaylistService()
    
    lazy var activityIndicator: UIActivityIndicatorView = ControllerHelper.newActivityIndicatorForView(self.view)

    @IBOutlet public weak var createPlaylistButton: UIButton!

    override public func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation

    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let spotifyPlaylistTableController = segue.destinationViewController as! SpotifyPlaylistTableController
        spotifyPlaylistTableController.playlist = self.playlist
    }
    
    @IBAction public func createPlaylistPressed(sender: AnyObject) {
        ControllerHelper.handleBeginBackgroundActivityForView(view, activityIndicator: activityIndicator)
        dispatch_async(dispatch_get_main_queue()) {
            self.playlistService.createPlaylist(numberOfSongs: 10) {
                playlistResult in
                
                switch (playlistResult) {
                case .Failure(let error):
                    println("Error creating playlist: \(error)")
                    ControllerHelper.displaySimpleAlertForTitle("Unable to Create Your Playlist", andError: error, onController: self)
                case .Success(let playlist):
                    self.handleCreatedPlaylist(playlist, sender: sender)
                }
                ControllerHelper.handleCompleteBackgroundActivityForView(self.view, activityIndicator: self.activityIndicator)
            }
        }
    }
    
    func handleCreatedPlaylist(playlist: Playlist, sender: AnyObject) {
        println("Playlist: \(playlist)")
        self.playlist = playlist
        self.performSegueWithIdentifier("CreatePlaylistSegue", sender: sender)
    }
}
