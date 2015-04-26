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
        let playlistTableViewController = segue.destinationViewController as! PlaylistTableViewController
        playlistTableViewController.playlist = self.playlist
    }
    
    @IBAction public func createPlaylistPressed(sender: AnyObject) {
        ControllerHelper.handleBeginBackgroundActivityForView(view, activityIndicator: activityIndicator)
        dispatch_async(dispatch_get_main_queue()) {
            self.playlistService.createPlaylist(numberOfSongs: 10) {
                playlistResult in
                
                switch (playlistResult) {
                case .Failure(let error):
                    println("Error creating playlist: \(error)")
                    ControllerHelper.displaySimpleAlertForTitle("Unable to Create Your Playlist", andMessage: error.userInfo?[NSLocalizedDescriptionKey] as! String, onController: self)
                case .Success(let playlist):
                    self.playlist = playlist
                    self.performSegueWithIdentifier("CreatePlaylistSegue", sender: sender)
                }
                ControllerHelper.handleCompleteBackgroundActivityForView(self.view, activityIndicator: self.activityIndicator)
            }
        }
    }
}
