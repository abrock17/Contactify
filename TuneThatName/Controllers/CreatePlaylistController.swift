import UIKit

public class CreatePlaylistController: UIViewController {
    
    public var playlistService = PlaylistService()
    
    var playlist: Playlist?
    
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
        
        let playlistTableViewController = segue.destinationViewController as PlaylistTableViewController
        playlistTableViewController.playlist = self.playlist
    }
    
    @IBAction public func createPlaylistPressed(sender: AnyObject) {
        playlistService.createPlaylist() {
            playlistResult in

            switch (playlistResult) {
            case .Failure(let error):
                println("Error creating playlist: \(error)")
                ControllerErrorHelper.displaySimpleAlertForTitle("Unable to Create Your Playlist", andMessage: error.userInfo?[NSLocalizedDescriptionKey] as String, onController: self)
            case .Success(let playlist):
                self.playlist = playlist
                self.performSegueWithIdentifier("CreatePlaylistSegue", sender: sender)
            }
        }
    }
}
