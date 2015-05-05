import UIKit

public class PlaylistTableViewController: UITableViewController, SPTAuthViewDelegate {
    
    enum SpotifyPostLoginAction {
        case PlaySong(Song)
        case SavePlaylist
    }
    
    public var playlist: Playlist!
    var spotifyPostLoginAction: SpotifyPostLoginAction! = SpotifyPostLoginAction.SavePlaylist
    
    public var spotifyAuth: SPTAuth! = SPTAuth.defaultInstance()
    var spotifyAuthController: SPTAuthViewController!
    var spotifyAudioController: SPTAudioStreamingController!
    
    public var echoNestService = EchoNestService()
    public var spotifyService = SpotifyService()

    lazy var activityIndicator: UIActivityIndicatorView = ControllerHelper.newActivityIndicatorForView(self.tableView)
    
    @IBOutlet public weak var saveButton: UIBarButtonItem!
    
    @IBOutlet public weak var playPauseButton: UIBarButtonItem!
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        if spotifyAudioController == nil {
            spotifyAudioController = SPTAudioStreamingController(clientId: SpotifyService.clientID)
        }
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        updateSaveButtonForUnsavedPlaylist()
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(false, animated: animated)
    }

    override public func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setToolbarHidden(true, animated: animated)
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
    
    override public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let song = playlist.songs[indexPath.row]
        
        if spotifyAuth.session == nil || !spotifyAuth.session.isValid() {
            spotifyPostLoginAction = SpotifyPostLoginAction.PlaySong(song)
            openLogin()
        } else {
            playSong(song)
        }
    }
    
    func playSong(song: Song) {
        let errorTitle = "Unable to play song"
        
        ControllerHelper.handleBeginBackgroundActivityForView(view, activityIndicator: activityIndicator)
        spotifyAudioController.loginWithSession(spotifyAuth.session) {
            error in
            
            if error != nil {
                ControllerHelper.displaySimpleAlertForTitle(errorTitle, andMessage: error.userInfo?[NSLocalizedDescriptionKey] as! String, onController: self)
            } else {
                self.spotifyAudioController.playURIs([song.uri!], fromIndex: 0) {
                    error in
                    
                    if error != nil {
                        ControllerHelper.displaySimpleAlertForTitle(errorTitle, andMessage: error.userInfo?[NSLocalizedDescriptionKey] as! String, onController: self)
                    }
                    ControllerHelper.handleCompleteBackgroundActivityForView(self.view, activityIndicator: self.activityIndicator)
                    self.updatePlayPauseButton()
                }
            }
        }
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
            spotifyPostLoginAction = SpotifyPostLoginAction.SavePlaylist
            openLogin()
        } else {
            savePlaylist()
        }
    }
    
    func openLogin() {
        spotifyAuthController = SPTAuthViewController.authenticationViewControllerWithAuth(spotifyAuth)
        spotifyAuthController.delegate = self
        spotifyAuthController.modalPresentationStyle = UIModalPresentationStyle.CurrentContext
        spotifyAuthController.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        
        self.modalPresentationStyle = UIModalPresentationStyle.CurrentContext
        self.definesPresentationContext = true
        
        presentViewController(self.spotifyAuthController, animated: false, completion: nil)
    }
    
    public func authenticationViewController(viewController: SPTAuthViewController, didFailToLogin error: NSError) {
        println("Login failed... error: \(error)")
    }
    
    public func authenticationViewController(viewController: SPTAuthViewController, didLoginWithSession session: SPTSession) {
        println("Login succeeded... session: \(session)")
        switch (spotifyPostLoginAction!) {
        case .PlaySong(let song):
            playSong(song)
        case .SavePlaylist:
            savePlaylist()
        }
    }
    
    public func authenticationViewControllerDidCancelLogin(viewController: SPTAuthViewController) {
        println("Login cancelled")
    }
    
    func savePlaylist() {
        updateSaveButtonForPlaylistSaveInProgress()
        ControllerHelper.handleBeginBackgroundActivityForView(view, activityIndicator: activityIndicator)
        let session = spotifyAuth.session
        println("access token: \(session?.accessToken)")
        dispatch_async(dispatch_get_main_queue()) {
            self.spotifyService.savePlaylist(self.playlist, session: session) {
                playlistResult in
                
                switch (playlistResult) {
                case .Success(let playlist):
                    self.playlist = playlist
                    self.updateSaveButtonAfterPlaylistSaved()
                case .Failure(let error):
                    println("Error saving playlist: \(error)")
                    ControllerHelper.displaySimpleAlertForTitle("Unable to Save Your Playlist", andMessage: error.userInfo?[NSLocalizedDescriptionKey] as! String, onController: self)
                }
                ControllerHelper.handleCompleteBackgroundActivityForView(self.view, activityIndicator: self.activityIndicator)
            }
        }
    }
    
    func updateSaveButtonForUnsavedPlaylist() {
        self.saveButton.title = "Save to Spotify"
        self.saveButton.enabled = true
    }
    
    func updateSaveButtonForPlaylistSaveInProgress() {
        self.saveButton.title = "Saving Playlist"
        self.saveButton.enabled = false
    }
    
    func updateSaveButtonAfterPlaylistSaved() {
        self.saveButton.title = "Playlist Saved"
        self.saveButton.enabled = false
    }
    
    @IBAction func playPausePressed(sender: UIBarButtonItem) {
        spotifyAudioController.setIsPlaying(!spotifyAudioController.isPlaying) {
            error in
            
            self.updatePlayPauseButton()
        }
    }
    
    func updatePlayPauseButton() {
        let buttonSystemItem = spotifyAudioController.isPlaying ? UIBarButtonSystemItem.Pause : UIBarButtonSystemItem.Play
        let updatedButton = UIBarButtonItem(barButtonSystemItem: buttonSystemItem, target: self, action: "playPausePressed:")
        self.navigationController?.toolbar.items?.removeLast()
        self.navigationController?.toolbar.items?.append(updatedButton)
    }
}
