import UIKit

public class SpotifyPlaylistTableController: UITableViewController, SPTAuthViewDelegate, SpotifyPlaybackDelegate {
    
    public enum SpotifySessionAction {
        case PlayPlaylist(index: Int)
        case SavePlaylist
    }
    
    let playSongErrorTitle = "Unable to Play Song"
    let songViewButtonWidth: CGFloat = 29
    
    public var playlist: Playlist!
    public var spotifySessionAction: SpotifySessionAction!
    var hasPlayed: Bool {
        return self.spotifyAudioFacade.currentSpotifyTrack != nil
    }
    
    public var spotifyAuth: SPTAuth! = SPTAuth.defaultInstance()
    var spotifyAuthController: SPTAuthViewController!
    
    public var spotifyService = SpotifyService()
    public var spotifyAudioFacadeOverride: SpotifyAudioFacade!
    lazy var spotifyAudioFacade: SpotifyAudioFacade! = {
        return self.spotifyAudioFacadeOverride != nil ? self.spotifyAudioFacadeOverride : SpotifyAudioFacadeImpl(spotifyPlaybackDelegate: self)
    }()
    public var controllerHelper = ControllerHelper()

    lazy var activityIndicator: UIActivityIndicatorView = ControllerHelper.newActivityIndicatorForView(self.tableView)
    
    @IBOutlet public weak var playlistNameButton: UIButton!
    @IBOutlet public weak var saveButton: UIBarButtonItem!
    @IBOutlet public weak var playPauseButton: UIBarButtonItem!
    @IBOutlet public weak var songViewButton: UIBarButtonItem!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        self.tableView.allowsSelectionDuringEditing = true
        
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
        cell.detailTextLabel?.text = song.displayArtistName

        return cell
    }
    
    override public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        playFromIndex(indexPath.row)
    }
    
    override public func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if editing {
            updateSaveButtonForPlaylistEditInProgress()
        } else {
            updateSaveButtonForUnsavedPlaylist()
        }
        
        selectRowForSpotifyTrack(spotifyAudioFacade.currentSpotifyTrack)
    }
    
    func syncEditedPlaylist() {
        selectRowForSpotifyTrack(spotifyAudioFacade.currentSpotifyTrack)
        let currentIndex = getIndexForSpotifyTrack(spotifyAudioFacade.currentSpotifyTrack)
        self.spotifyAudioFacade.updatePlaylist(self.playlist, withIndex: currentIndex ?? 0) {
            error in
            
            if error != nil {
                println("Error updating queue: \(error)")
            }
        }
    }
    
    func selectRowForSpotifyTrack(spotifyTrack: SpotifyTrack?) {
        let currentTrackIndex = getIndexForSpotifyTrack(spotifyTrack)
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            if let index = currentTrackIndex {
                self.tableView.selectRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0), animated: false, scrollPosition: UITableViewScrollPosition.None)
            } else if let selectedIndexPath = self.tableView.indexPathForSelectedRow() {
                self.tableView.deselectRowAtIndexPath(selectedIndexPath, animated: false)
            }
        }
    }
    
    func getIndexForSpotifyTrack(spotifyTrack: SpotifyTrack?) -> Int? {
        var indexForURI: Int?
        if let uri = spotifyTrack?.uri {
            for (index, song) in enumerate(self.playlist.songs) {
                if song.uri == uri {
                    indexForURI = index
                }
            }
        }
        
        return indexForURI
    }

    override public func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override public func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        return [UITableViewRowAction(style: .Default, title: "Delete", handler: handleDeleteRow)]
    }
    
    public func handleDeleteRow(rowAction: UITableViewRowAction!, indexPath: NSIndexPath!) {
        let deletedSong = self.playlist.songs.removeAtIndex(indexPath.row)
        self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        if hasPlayed {
            self.syncEditedPlaylist()
            if spotifyAudioFacade.currentSpotifyTrack?.uri == deletedSong.uri {
                self.stopPlay()
            }
        }
    }
    
    func stopPlay() {
        self.spotifyAudioFacade.stopPlay() {
            error in
            if error != nil {
                print("Error stopping play: \(error)")
            }
        }
    }
    
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

    override public func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        let song = playlist.songs.removeAtIndex(fromIndexPath.row)
        playlist.songs.insert(song, atIndex: toIndexPath.row)
        if hasPlayed {
            syncEditedPlaylist()
        }
    }

    override public func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }

    // MARK: - Navigation

    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let destinationViewController: AnyObject = segue.destinationViewController
        if destinationViewController is CreatePlaylistController {
            stopPlay()
        } else if let spotifyTrackViewController = destinationViewController as? SpotifyTrackViewController {
            spotifyTrackViewController.spotifyAudioFacade = spotifyAudioFacade
        }
    }
    
    @IBAction public func savePlaylistPressed(sender: AnyObject) {
        if sessionIsValid() {
            savePlaylist()
        } else {
            refreshSession(SpotifySessionAction.SavePlaylist)
        }
    }
    
    func sessionIsValid() -> Bool {
        return spotifyAuth.session != nil && spotifyAuth.session.isValid()
    }
    
    func refreshSession(spotifySessionAction: SpotifySessionAction) {
        self.spotifySessionAction = spotifySessionAction

        if spotifyAuth.hasTokenRefreshService {
            ControllerHelper.handleBeginBackgroundActivityForView(view, activityIndicator: activityIndicator)
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                self.spotifyAuth.renewSession(self.spotifyAuth.session) {
                    error, session in
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        if error != nil {
                            println("Error renewing session: \(error)")
                        }
                        ControllerHelper.handleCompleteBackgroundActivityForView(self.view, activityIndicator: self.activityIndicator)
                        if session != nil {
                            self.spotifyAuth.session = session
                            self.doSpotifySessionAction()
                        } else {
                            self.openLogin()
                        }
                    }
                }
            }
        } else {
            self.openLogin()
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
        doSpotifySessionAction()
    }
    
    func doSpotifySessionAction() {
        switch (spotifySessionAction!) {
        case .PlayPlaylist(let index):
            playFromIndex(index)
        case .SavePlaylist:
            savePlaylist()
        }
    }
    
    public func authenticationViewControllerDidCancelLogin(viewController: SPTAuthViewController) {
    }
    
    @IBAction func playlistNamePressed(sender: UIButton) {
        presentPlaylistNameEntry(updatePlaylistName)
    }
    
    func presentPlaylistNameEntry(completionHandler: String -> Void) {
        let playlistNameEntryController = PlaylistNameEntryController(currentName: playlist.name, completionHandler: completionHandler)
        presentViewController(playlistNameEntryController, animated: true, completion: nil)
    }
    
    func updatePlaylistName(playlistName: String) {
        playlist.name = playlistName
        playlistNameButton.setTitle(playlist.name, forState: UIControlState.Normal)
        updateSaveButtonForUnsavedPlaylist()
    }
    
    func updatePlaylistNameAndSave(playlistName: String) {
        updatePlaylistName(playlistName)
        savePlaylist()
    }
    
    func savePlaylist() {
        if playlist.name != nil {
            updateSaveButtonForPlaylistSaveInProgress()
            ControllerHelper.handleBeginBackgroundActivityForView(view, activityIndicator: activityIndicator)
            let session = spotifyAuth.session
            println("access token: \(session?.accessToken)")
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                self.spotifyService.savePlaylist(self.playlist, session: session) {
                    playlistResult in
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        switch (playlistResult) {
                        case .Success(let playlist):
                            self.playlist = playlist
                            self.updateSaveButtonAfterPlaylistSaved()
                        case .Failure(let error):
                            println("Error saving playlist: \(error)")
                            ControllerHelper.displaySimpleAlertForTitle("Unable to Save Your Playlist", andError: error, onController: self)
                            self.updateSaveButtonForUnsavedPlaylist()
                        }
                        ControllerHelper.handleCompleteBackgroundActivityForView(self.view, activityIndicator: self.activityIndicator)
                    }
                }
            }
        } else {
            presentPlaylistNameEntry(updatePlaylistNameAndSave)
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
    
    func updateSaveButtonForPlaylistEditInProgress() {
        self.saveButton.title = "Editing Playlist"
        self.saveButton.enabled = false
    }
    
    @IBAction func playPausePressed(sender: UIBarButtonItem) {
        if !hasPlayed {
            playFromIndex(0)
        } else {
            spotifyAudioFacade.togglePlay() {
                error in
                if error != nil {
                    ControllerHelper.displaySimpleAlertForTitle(self.playSongErrorTitle, andError: error, onController: self)
                }
            }
        }
    }
    
    func playFromIndex(index: Int) {
        if sessionIsValid() {
            ControllerHelper.handleBeginBackgroundActivityForView(view, activityIndicator: activityIndicator)
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                self.spotifyAudioFacade.playPlaylist(self.playlist, fromIndex: index, inSession: self.spotifyAuth.session) {
                    error in
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        if error != nil {
                            ControllerHelper.displaySimpleAlertForTitle(self.playSongErrorTitle, andError: error, onController: self)
                        } else if !self.editing {
                            self.performSegueWithIdentifier("ShowSpotifyTrackSegue", sender: nil)
                        }
                        ControllerHelper.handleCompleteBackgroundActivityForView(self.view, activityIndicator: self.activityIndicator)
                    }
                }
            }
        } else {
            refreshSession(SpotifySessionAction.PlayPlaylist(index: index))
        }
    }
    
    @IBAction func songViewPressed(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("ShowSpotifyTrackSegue", sender: sender)
    }
    
    public func changedPlaybackStatus(isPlaying: Bool) {
        updatePlayPauseButton(isPlaying)
    }
    
    func updatePlayPauseButton(isPlaying: Bool) {
        let buttonSystemItem = isPlaying ? UIBarButtonSystemItem.Pause : UIBarButtonSystemItem.Play
        let updatedButton = UIBarButtonItem(barButtonSystemItem: buttonSystemItem, target: self, action: "playPausePressed:")
        self.toolbarItems?.removeLast()
        self.toolbarItems?.append(updatedButton)
    }
    
    public func startedPlayingSpotifyTrack(spotifyTrack: SpotifyTrack?) {
        selectRowForSpotifyTrack(spotifyTrack)
        updateSongViewButtonForTrack(spotifyTrack)
    }
    
    func updateSongViewButtonForTrack(spotifyTrack: SpotifyTrack?) {
        if let albumImageURL = spotifyTrack?.albumSmallestCoverImageURL {
            controllerHelper.getImageForURL(albumImageURL) {
                image in
                self.updateSongViewButtonForImage(image)
            }
        } else {
            updateSongViewButtonForImage(nil)
        }
    }
    
    func updateSongViewButtonForImage(image: UIImage?) {
        let imageButton: UIButton
        if let image = image {
            imageButton = UIButton(frame: CGRectMake(0, 0, self.songViewButtonWidth, self.songViewButtonWidth))
            imageButton.setBackgroundImage(image, forState: UIControlState.Normal)
        } else {
            imageButton = UIButton()
            imageButton.enabled = false
        }
        imageButton.addTarget(self, action: "songViewPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        let updatedBarButton = UIBarButtonItem(customView: imageButton)
        self.toolbarItems?.removeAtIndex(0)
        self.toolbarItems?.insert(updatedBarButton, atIndex: 0)
    }
    
    @IBAction public func unwindToSpotifyPlaylistTable(sender: UIStoryboardSegue) {
        spotifyAudioFacade.playbackDelegate = self
        startedPlayingSpotifyTrack(spotifyAudioFacade.currentSpotifyTrack)
        changedPlaybackStatus(spotifyAudioFacade.isPlaying)
    }
}
