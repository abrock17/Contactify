import UIKit

public class SpotifyPlaylistTableController: UITableViewController, SPTAuthViewDelegate, SpotifyPlaybackDelegate {
    
    public enum SpotifySessionAction {
        case PlayPlaylist(index: Int)
        case SavePlaylist
    }
    
    enum PlaylistState {
        case Unsaved, Editing, Saving, Saved
    }
    
    let playSongErrorTitle = "Unable to Play Song"
    let songViewButtonWidth: CGFloat = 29
    
    public var playlist: Playlist!
    public var spotifySessionAction: SpotifySessionAction!
    var playlistState: PlaylistState!
    var hasPlayed: Bool {
        return self.spotifyAudioFacade.currentSpotifyTrack != nil
    }
    public var songReplacementIndexPath: NSIndexPath?
    
    public var spotifyAuth: SPTAuth! = SPTAuth.defaultInstance()
    var spotifyAuthController: SPTAuthViewController!
    
    public var spotifyService = SpotifyService()
    public var spotifyAudioFacadeOverride: SpotifyAudioFacade!
    lazy var spotifyAudioFacade: SpotifyAudioFacade! = {
        return self.spotifyAudioFacadeOverride != nil ? self.spotifyAudioFacadeOverride : SpotifyAudioFacadeImpl(spotifyPlaybackDelegate: self)
    }()
    public var controllerHelper = ControllerHelper()

    lazy var activityIndicator: UIActivityIndicatorView = ControllerHelper.newActivityIndicatorForView(self.navigationController!.view)
    
    @IBOutlet public weak var playlistNameButton: UIButton!
    @IBOutlet public weak var newPlaylistButton: UIBarButtonItem!
    @IBOutlet public weak var saveButton: UIBarButtonItem!
    @IBOutlet public weak var playPauseButton: UIBarButtonItem!
    @IBOutlet public weak var songViewButton: UIBarButtonItem!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        self.tableView.allowsSelectionDuringEditing = true
        
        updatePlaylistState(.Unsaved)
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
        let cell = tableView.dequeueReusableCellWithIdentifier("PlaylistTableCell", forIndexPath: indexPath)

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
            updatePlaylistState(.Editing)
        } else {
            updatePlaylistState(.Unsaved)
        }
        
        selectRowForSpotifyTrack(spotifyAudioFacade.currentSpotifyTrack)
    }
    
    func syncEditedPlaylist() {
        selectRowForSpotifyTrack(spotifyAudioFacade.currentSpotifyTrack)
        let currentIndex = getIndexForSpotifyTrack(spotifyAudioFacade.currentSpotifyTrack)
        self.spotifyAudioFacade.updatePlaylist(self.playlist, withIndex: currentIndex ?? 0) {
            error in
            
            if error != nil {
                print("Error updating queue: \(error)")
            }
        }
    }
    
    func selectRowForSpotifyTrack(spotifyTrack: SpotifyTrack?) {
        let currentTrackIndex = getIndexForSpotifyTrack(spotifyTrack)
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            if let index = currentTrackIndex {
                self.tableView.selectRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0), animated: false, scrollPosition: UITableViewScrollPosition.None)
            } else if let selectedIndexPath = self.tableView.indexPathForSelectedRow {
                self.tableView.deselectRowAtIndexPath(selectedIndexPath, animated: false)
            }
        }
    }
    
    func getIndexForSpotifyTrack(spotifyTrack: SpotifyTrack?) -> Int? {
        var indexForURI: Int?
        if let uri = spotifyTrack?.uri {
            for (index, song) in self.playlist.songs.enumerate() {
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
    
    override public func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        return [
            UITableViewRowAction(style: .Default, title: "Delete", handler: handleDeleteRow),
            UITableViewRowAction(style: .Normal, title: "Replace", handler: handleReplaceRow)
        ]
    }
    
    public func handleDeleteRow(rowAction: UITableViewRowAction!, indexPath: NSIndexPath!) {
        let deletedSong = self.playlist.songsWithContacts.removeAtIndex(indexPath.row)
        self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        if hasPlayed {
            self.syncEditedPlaylist()
            if spotifyAudioFacade.currentSpotifyTrack?.uri == deletedSong.song.uri {
                self.stopPlay()
            }
        }
    }
    
    public func handleReplaceRow(rowAction: UITableViewRowAction!, indexPath: NSIndexPath!) {
        songReplacementIndexPath = indexPath
        let songWithContact = playlist.songsWithContacts[indexPath.row]
        if let contact = songWithContact.contact {
            presentSongReplacementAlertForContact(contact)
        } else {
            performSegueWithIdentifier("EnterNameSegue", sender: nil)
        }
    }
    
    func presentSongReplacementAlertForContact(contact: Contact) {
        let alertController = UIAlertController(title: "Replace this Song",
            message: "(For \(contact.fullName))", preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Use the Same Name", style: UIAlertActionStyle.Default) {
            uiAlertAction in
            self.performSegueWithIdentifier("SelectSongSameContactSegue", sender: nil)
            })
        alertController.addAction(UIAlertAction(title: "Use a Different Name", style: UIAlertActionStyle.Default) {
            uiAlertAction in
            self.performSegueWithIdentifier("EnterNameSegue", sender: nil)
            })
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    public func completeReplacementWithSong(song: Song, andContact contact: Contact?) {
        navigationController?.popToViewController(self, animated: true)
        if let indexPath = songReplacementIndexPath {
            let oldSong = playlist.songsWithContacts[indexPath.row].song
            playlist.songsWithContacts[indexPath.row] = (song: song, contact: contact)
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            if hasPlayed {
                if spotifyAudioFacade.currentSpotifyTrack?.uri == oldSong.uri {
                    playFromIndex(indexPath.row)
                } else {
                    syncEditedPlaylist()
                }
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
    
    override public func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        let songWithContact = playlist.songsWithContacts.removeAtIndex(fromIndexPath.row)
        playlist.songsWithContacts.insert(songWithContact, atIndex: toIndexPath.row)
        if hasPlayed {
            syncEditedPlaylist()
        }
    }

    override public func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    // MARK: - Navigation

    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let destinationViewController: AnyObject = segue.destinationViewController
        if destinationViewController is CreatePlaylistController {
            stopPlay()
        } else if let spotifyTrackViewController = destinationViewController as? SpotifyTrackViewController {
            spotifyTrackViewController.spotifyAudioFacade = spotifyAudioFacade
        } else if let spotifySongSelectionController = destinationViewController as? SpotifySongSelectionTableController {
            spotifySongSelectionController.searchContact = playlist.songsWithContacts[songReplacementIndexPath!.row].contact
            spotifySongSelectionController.songSelectionCompletionHandler = completeReplacementWithSong
        } else if let singleNameEntryController = destinationViewController as? SingleNameEntryController {
            singleNameEntryController.songSelectionCompletionHandler = completeReplacementWithSong
        }
    }
    
    @IBAction func newPlaylistPressed(sender: UIBarButtonItem) {
        if PlaylistState.Saved == playlistState {
            performSegueWithIdentifier("UnwindToCreatePlaylistFromPlaylistTableSegue", sender: sender)
        } else {
            presentUnsavedPlaylistDialog(sender)
        }
    }
    
    func presentUnsavedPlaylistDialog(sender: AnyObject) {
        let alertController = UIAlertController(title: "Unsaved Playlist", message: "Abandon changes to this playlist?", preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Save Playlist", style: UIAlertActionStyle.Default) {
            uiAlertAction in
            
            self.savePlaylist()
            })
        alertController.addAction(UIAlertAction(title: "Abandon Changes", style: UIAlertActionStyle.Destructive) {
            uiAlertAction in
            
            self.performSegueWithIdentifier("UnwindToCreatePlaylistFromPlaylistTableSegue", sender: sender)
            })
        presentViewController(alertController, animated: true, completion: nil)
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
                            print("Error renewing session: \(error)")
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
        print("Login failed... error: \(error)")
    }
    
    public func authenticationViewController(viewController: SPTAuthViewController, didLoginWithSession session: SPTSession) {
        print("Login succeeded... session: \(session)")
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
        updatePlaylistState(.Unsaved)
    }
    
    func updatePlaylistNameAndSave(playlistName: String) {
        updatePlaylistName(playlistName)
        savePlaylist()
    }
    
    func savePlaylist() {
        if playlist.name != nil {
            updatePlaylistState(.Saving)
            ControllerHelper.handleBeginBackgroundActivityForView(view, activityIndicator: activityIndicator)
            let session = spotifyAuth.session
            print("access token: \(session?.accessToken)")
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                self.spotifyService.savePlaylist(self.playlist, session: session) {
                    playlistResult in
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        switch (playlistResult) {
                        case .Success(let playlist):
                            self.playlist = playlist
                            self.updatePlaylistState(.Saved)
                        case .Failure(let error):
                            print("Error saving playlist: \(error)")
                            ControllerHelper.displaySimpleAlertForTitle("Unable to Save Your Playlist", andError: error, onController: self)
                            self.updatePlaylistState(.Unsaved)
                        }
                        ControllerHelper.handleCompleteBackgroundActivityForView(self.view, activityIndicator: self.activityIndicator)
                    }
                }
            }
        } else {
            presentPlaylistNameEntry(updatePlaylistNameAndSave)
        }
    }
    
    func updatePlaylistState(state: PlaylistState) {
        playlistState = state
        var buttonEnabled = false
        let buttonTitle: String
        
        switch state {
        case .Unsaved:
            buttonEnabled = true
            buttonTitle = "Save to Spotify"
        case .Editing:
            buttonTitle = "Editing Playlist"
        case .Saving:
            buttonTitle = "Saving Playlist"
        case .Saved:
            buttonTitle = "Playlist Saved"
        }
        
        saveButton.title = buttonTitle
        saveButton.enabled = buttonEnabled
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
    
    public func changedCurrentTrack(spotifyTrack: SpotifyTrack?) {
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
        changedCurrentTrack(spotifyAudioFacade.currentSpotifyTrack)
        changedPlaybackStatus(spotifyAudioFacade.isPlaying)
    }
}
