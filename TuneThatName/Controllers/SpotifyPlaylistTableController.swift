import UIKit

public class SpotifyPlaylistTableController: UITableViewController, SpotifyPlaybackDelegate {
    
    enum PlaylistState {
        case Unsaved, Editing, Saving, Saved
    }
    
    public var playlist: Playlist!
    var playlistState: PlaylistState!
    var hasPlayed: Bool {
        return self.spotifyAudioFacade.currentSpotifyTrack != nil
    }
    public var songReplacementIndexPath: NSIndexPath?
    
    public var spotifyPlaylistService = SpotifyPlaylistService()
    public var spotifyAudioFacadeOverride: SpotifyAudioFacade!
    lazy var spotifyAudioFacade: SpotifyAudioFacade! = {
        return self.spotifyAudioFacadeOverride != nil ? self.spotifyAudioFacadeOverride : SpotifyAudioFacadeImpl.sharedInstance
    }()
    public var controllerHelper = ControllerHelper()

    lazy var activityIndicator: UIActivityIndicatorView = ControllerHelper.newActivityIndicatorForView(self.navigationController!.view)
    
    @IBOutlet public weak var playlistNameButton: UIButton!
    @IBOutlet public weak var newPlaylistButton: UIBarButtonItem!
    @IBOutlet public weak var saveButton: UIBarButtonItem!
    @IBOutlet public weak var playPauseButton: UIBarButtonItem!
    @IBOutlet public weak var songViewButton: UIBarButtonItem!
    @IBOutlet weak var spotifyActionsButton: UIBarButtonItem!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItems = [self.editButtonItem()]
        self.tableView.allowsSelectionDuringEditing = true
        
        updatePlaylistState(.Unsaved)
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        spotifyAudioFacade.playbackDelegate = self
        self.navigationController?.setToolbarHidden(false, animated: animated)

        setupSpotifyActionsButton()
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
        return 1
    }

    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
            let addButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: "addSong:")
            self.navigationItem.rightBarButtonItems = [self.editButtonItem(), addButton]
            updatePlaylistState(.Editing)
        } else {
            self.navigationItem.rightBarButtonItems = [self.editButtonItem()]
            updatePlaylistState(.Unsaved)
        }
        
        selectRowForSpotifyTrack(spotifyAudioFacade.currentSpotifyTrack, scroll: !editing)
    }
    
    func syncEditedPlaylist(scrollToSelectedRow scroll: Bool) {
        selectRowForSpotifyTrack(spotifyAudioFacade.currentSpotifyTrack, scroll: scroll)
        let currentIndex = ControllerHelper.getIndexForSpotifyTrack(spotifyAudioFacade.currentSpotifyTrack, inSongs: playlist.songs)
        self.spotifyAudioFacade.updatePlaylist(self.playlist, withIndex: currentIndex ?? 0) {
            error in
            
            if error != nil {
                print("Error updating queue: \(error)")
            }
        }
    }
    
    func selectRowForSpotifyTrack(spotifyTrack: SpotifyTrack?, scroll: Bool) {
        let currentTrackIndex = ControllerHelper.getIndexForSpotifyTrack(spotifyTrack, inSongs: playlist.songs)
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            if let index = currentTrackIndex {
                self.tableView.selectRowAtIndexPath(
                    NSIndexPath(forRow: index, inSection: 0),
                    animated: true,
                    scrollPosition: scroll ? .Middle : .None
                )
            } else if let selectedIndexPath = self.tableView.indexPathForSelectedRow {
                self.tableView.deselectRowAtIndexPath(selectedIndexPath, animated: false)
            }
        }
    }
    
    public func addSong(sender: UIBarButtonItem) {
        performSegueWithIdentifier("EnterNameSegue", sender: sender)
        songReplacementIndexPath = nil
    }
    
    override public func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override public func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        return [
            UITableViewRowAction(style: .Destructive, title: "Delete", handler: handleDeleteRow),
            UITableViewRowAction(style: .Normal, title: "Replace", handler: handleReplaceRow)
        ]
    }
    
    public func handleDeleteRow(rowAction: UITableViewRowAction!, indexPath: NSIndexPath!) {
        let deletedSong = self.playlist.songsWithContacts.removeAtIndex(indexPath.row)
        self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        if hasPlayed {
            self.syncEditedPlaylist(scrollToSelectedRow: false)
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
    
    public func completeSelectionOfSong(song: Song, withContact contact: Contact?) {
        navigationController?.popToViewController(self, animated: true)
        if let indexPath = songReplacementIndexPath {
            let oldSong = playlist.songsWithContacts[indexPath.row].song
            playlist.songsWithContacts[indexPath.row] = (song: song, contact: contact)
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            if hasPlayed {
                if spotifyAudioFacade.currentSpotifyTrack?.uri == oldSong.uri {
                    playFromIndex(indexPath.row)
                } else {
                    syncEditedPlaylist(scrollToSelectedRow: false)
                }
            }
        } else {
            playlist.songsWithContacts.append((song: song, contact: contact))
            tableView.reloadData()
            syncEditedPlaylist(scrollToSelectedRow: true)
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
            syncEditedPlaylist(scrollToSelectedRow: false)
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
            spotifySongSelectionController.songSelectionCompletionHandler = completeSelectionOfSong
        } else if let singleNameEntryController = destinationViewController as? SingleNameEntryController {
            singleNameEntryController.songSelectionCompletionHandler = completeSelectionOfSong
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
        savePlaylist()
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
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                self.spotifyPlaylistService.savePlaylist(self.playlist) {
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
                        case .Canceled:
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
                    ControllerHelper.displaySimpleAlertForTitle(Constants.Error.GenericPlaybackMessage,
                        andError: error, onController: self)
                }
            }
        }
    }
    
    func playFromIndex(index: Int) {
        ControllerHelper.handleBeginBackgroundActivityForView(view, activityIndicator: activityIndicator)
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.spotifyAudioFacade.playTracksForURIs(self.playlist.songURIs, fromIndex: index) {
                error in
                
                dispatch_async(dispatch_get_main_queue()) {
                    if error != nil {
                        if error.code != Constants.Error.SpotifyLoginCanceledCode {
                            ControllerHelper.displaySimpleAlertForTitle(Constants.Error.GenericPlaybackMessage,
                                andError: error, onController: self)
                        }
                    } else if !self.editing {
                        self.performSegueWithIdentifier("ShowSpotifyTrackFromPlaylistSegue", sender: nil)
                    }
                    ControllerHelper.handleCompleteBackgroundActivityForView(self.view, activityIndicator: self.activityIndicator)
                }
            }
        }
    }
    
    @IBAction func songViewPressed(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("ShowSpotifyTrackFromPlaylistSegue", sender: sender)
    }
    
    public func changedPlaybackStatus(isPlaying: Bool) {
        ControllerHelper.updatePlayPauseButtonOnTarget(self, withAction: "playPausePressed:", forIsPlaying: isPlaying)
    }
    
    public func changedCurrentTrack(spotifyTrack: SpotifyTrack?) {
        selectRowForSpotifyTrack(spotifyTrack, scroll: !self.editing)
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
        ControllerHelper.updateBarButtonItemOnTarget(self, action: "songViewPressed:", atToolbarIndex: 0, withImage: image)
    }
    
    func setupSpotifyActionsButton() {
        ControllerHelper.updateBarButtonItemOnTarget(self, action: "spotifyActionsPressed:", atToolbarIndex: 1, withImage: UIImage(named: "Dakirby309-Simply-Styled-Spotify.ico"))
    }
    
    @IBAction public func spotifyActionsPressed(sender: AnyObject) {
        let spotifyActionSheet = SpotifyActionSheetController(presentingView: (sender as! UIView),
            application: UIApplication.sharedApplication(), spotifyAuthService: SpotifyAuthService())
        
        presentViewController(spotifyActionSheet, animated: true, completion: nil)
    }
}
