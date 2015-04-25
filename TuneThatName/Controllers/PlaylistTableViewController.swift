import UIKit

public class PlaylistTableViewController: UITableViewController, SPTAuthViewDelegate {
    
    public var playlist: Playlist!
    public var spotifyAuth: SPTAuth! = SPTAuth.defaultInstance()
    
    public var echoNestService = EchoNestService()
    public var spotifyService = SpotifyService()

    var authViewController: SPTAuthViewController!
    
    lazy var activityIndicator: UIActivityIndicatorView = ControllerHelper.newActivityIndicatorForView(self.tableView)
    
    @IBOutlet public weak var saveButton: UIBarButtonItem!
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        if playlist == nil {
            loadDummyPlaylist()
        }
        
        updateButtonForUnsavedPlaylist()
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(false, animated: animated)
    }

    override public func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setToolbarHidden(true, animated: animated)
    }
    
    func loadDummyPlaylist() {
        activityIndicator.startAnimating()
        playlist = Playlist(name: "Tune That Name")
        
        let names = ["John", "Paul", "George", "Ringo"]
        var retrievalCompleted = 0
        for name in names {
            echoNestService.findSong(titleSearchTerm: name) {
                (songResult: EchoNestService.SongResult) in
                
                switch (songResult) {
                case .Success(let song):
                    if let song = song {
                        self.playlist.songs.append(song)
                    }
                    println("song title: \(song?.title)")
                case .Failure(let error):
                    println("error: \(error)")
                }
                
                retrievalCompleted++
                if names.count == retrievalCompleted {
                    self.tableView.reloadData()
                    self.activityIndicator.stopAnimating()
                }
            }
        }
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return playlist.songs.count
    }

    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("PlaylistTableCell", forIndexPath: indexPath) as! UITableViewCell

        let song = playlist.songs[indexPath.row]
        cell.textLabel?.text = song.title
        cell.detailTextLabel?.text = song.artistName

        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */
    
    
    @IBAction public func savePlaylistPressed(sender: AnyObject) {
        if spotifyAuth.session == nil || !spotifyAuth.session.isValid() {
            openLogin()
        } else {
            savePlaylist()
        }
    }
    
    func openLogin() {
        authViewController = SPTAuthViewController.authenticationViewControllerWithAuth(spotifyAuth)
        authViewController.delegate = self
        authViewController.modalPresentationStyle = UIModalPresentationStyle.CurrentContext
        authViewController.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        
        self.modalPresentationStyle = UIModalPresentationStyle.CurrentContext
        self.definesPresentationContext = true
        
        presentViewController(self.authViewController, animated: false, completion: nil)
    }
    
    public func authenticationViewController(viewController: SPTAuthViewController, didFailToLogin error: NSError) {
        println("Login failed... error: \(error)")
    }
    
    public func authenticationViewController(viewController: SPTAuthViewController, didLoginWithSession session: SPTSession) {
        println("Login succeeded... session: \(session)")
        savePlaylist()
    }
    
    public func authenticationViewControllerDidCancelLogin(viewController: SPTAuthViewController) {
        println("Login cancelled")
    }
    
    func savePlaylist() {
        ControllerHelper.handleBeginBackgroundActivityForView(view, activityIndicator: activityIndicator)
        let session = spotifyAuth.session
        println("access token: \(session?.accessToken)")
        dispatch_async(dispatch_get_main_queue()) {
            self.spotifyService.savePlaylist(self.playlist, session: session) {
                playlistResult in
                
                switch (playlistResult) {
                case .Success(let playlist):
                    self.playlist = playlist
                    self.updateButtonAfterPlaylistSaved()
                case .Failure(let error):
                    println("Error saving playlist: \(error)")
                    ControllerHelper.displaySimpleAlertForTitle("Unable to Save Your Playlist", andMessage: error.userInfo?[NSLocalizedDescriptionKey] as! String, onController: self)
                }
                ControllerHelper.handleCompleteBackgroundActivityForView(self.view, activityIndicator: self.activityIndicator)
            }
        }
    }
    
    func updateButtonForUnsavedPlaylist() {
        self.saveButton.title = "Save to Spotify"
        self.saveButton.enabled = true
    }
    
    func updateButtonAfterPlaylistSaved() {
        self.saveButton.title = "Playlist Saved"
        self.saveButton.enabled = false
    }
}
