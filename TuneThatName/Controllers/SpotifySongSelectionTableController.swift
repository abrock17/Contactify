import UIKit

public class SpotifySongSelectionTableController: UITableViewController, SpotifyPlaybackDelegate {
    
    public var searchContact: Contact!
    public var songSelectionCompletionHandler: ((Song, Contact?) -> Void)!
    public var songs = [Song]()
    
    public var echoNestService = EchoNestService()
    public var preferencesService = PreferencesService()
    public var spotifyAudioFacadeOverride: SpotifyAudioFacade!
    lazy var spotifyAudioFacade: SpotifyAudioFacade! = {
        return self.spotifyAudioFacadeOverride != nil ? self.spotifyAudioFacadeOverride : SpotifyAudioFacadeImpl.sharedInstance
        }()
    public var spotifyUserService = SpotifyUserService()
    public var controllerHelper = ControllerHelper()
    
    lazy var activityIndicator: UIActivityIndicatorView = ControllerHelper.newActivityIndicatorForView(self.navigationController!.view)
    
    @IBOutlet public weak var doneButton: UIBarButtonItem!
    @IBOutlet public weak var playPauseButton: UIBarButtonItem!
    @IBOutlet public weak var songViewButton: UIBarButtonItem!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        clearsSelectionOnViewWillAppear = false
        doneButton.enabled = false
        populateSongs()
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        spotifyAudioFacade.playbackDelegate = self
        
        self.navigationController?.setToolbarHidden(false, animated: animated)
    }
    
    override public func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setToolbarHidden(true, animated: animated)
    }
    
    func populateSongs() {
        var playlistPreferences = preferencesService.retrievePlaylistPreferences()
        if playlistPreferences == nil {
            playlistPreferences = preferencesService.getDefaultPlaylistPreferences()
        }
        
        ControllerHelper.handleBeginBackgroundActivityForView(view, activityIndicator: activityIndicator)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.retrieveCurrentUser() {
                user in
                
                self.echoNestService.findSongs(titleSearchTerm: self.searchContact.searchString, withSongPreferences: playlistPreferences!.songPreferences, desiredNumberOfSongs: 20, inLocale: user.territory) {
                    songResult in
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        switch (songResult) {
                        case .Success(let songs):
                            self.songs = songs
                            self.tableView.reloadData()
                        case .Failure(let error):
                            ControllerHelper.displaySimpleAlertForTitle(Constants.Error.GenericSongSearchMessage, andError: error, onController: self) {
                                alertAction in
                                
                                self.navigationController?.popViewControllerAnimated(true)
                            }
                        }
                        ControllerHelper.handleCompleteBackgroundActivityForView(self.view, activityIndicator: self.activityIndicator)
                    }
                }
            }
        }
    }
    
    func retrieveCurrentUser(userRetrievalHandler: SPTUser -> Void) {
        self.spotifyUserService.retrieveCurrentUser() {
            userResult in
            
            switch (userResult) {
            case .Success(let user):
                userRetrievalHandler(user)
            case .Failure(let error):
                dispatch_async(dispatch_get_main_queue()) {
                    
                    ControllerHelper.displaySimpleAlertForTitle(Constants.Error.GenericSongSearchMessage, andError: error, onController: self)
                    ControllerHelper.handleCompleteBackgroundActivityForView(self.view, activityIndicator: self.activityIndicator)
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
        return songs.count
    }

    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SongSelectionTableCell", forIndexPath: indexPath) 
        
        let song = songs[indexPath.row]
        cell.textLabel?.text = song.title
        cell.detailTextLabel?.text = song.displayArtistName

        return cell
    }
    
    override public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        doneButton.enabled = true
        playFromIndex(indexPath.row)
    }
    
    func playFromIndex(index: Int) {
        let song = songs[index]
        
        ControllerHelper.handleBeginBackgroundActivityForView(view, activityIndicator: activityIndicator)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.spotifyAudioFacade.playTracksForURIs([song.uri], fromIndex: 0) {
                error in
                
                dispatch_async(dispatch_get_main_queue()) {
                    if error != nil && error.code != Constants.Error.SpotifyLoginCanceledCode {
                        ControllerHelper.displaySimpleAlertForTitle(Constants.Error.GenericPlaybackMessage, andError: error, onController: self)
                    }
                    ControllerHelper.handleCompleteBackgroundActivityForView(self.view, activityIndicator: self.activityIndicator)
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

    // MARK: - Navigation

    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let destinationViewController: AnyObject = segue.destinationViewController
        if let spotifyTrackViewController = destinationViewController as? SpotifyTrackViewController {
            spotifyTrackViewController.spotifyAudioFacade = spotifyAudioFacade
            spotifyTrackViewController.hidePreviousAndNextTrackButtons = true
        }
    }
    
    @IBAction func cancelPressed(sender: UIBarButtonItem) {
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func donePressed(sender: UIBarButtonItem) {
        let selectedSong = songs[tableView.indexPathForSelectedRow!.row]
        songSelectionCompletionHandler(selectedSong, searchContact)
    }
    
    @IBAction func playPausePressed(sender: UIBarButtonItem) {
        if spotifyAudioFacade.currentSpotifyTrack != nil {
            spotifyAudioFacade.togglePlay() {
                error in
                if error != nil {
                    ControllerHelper.displaySimpleAlertForTitle(Constants.Error.GenericPlaybackMessage, andError: error, onController: self)
                }
            }
        } else {
            playFromIndex(0)
        }
    }
    
    public func changedPlaybackStatus(isPlaying: Bool) {
        ControllerHelper.updatePlayPauseButtonOnTarget(self, withAction: "playPausePressed:", forIsPlaying: isPlaying)
    }
    
    public func changedCurrentTrack(spotifyTrack: SpotifyTrack?) {
        selectRowForSpotifyTrack(spotifyTrack)
        updateSongViewButtonForTrack(spotifyTrack)
    }
    
    func selectRowForSpotifyTrack(spotifyTrack: SpotifyTrack?) {
        if let index = ControllerHelper.getIndexForSpotifyTrack(spotifyTrack, inSongs: songs) {
            self.tableView.selectRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0), animated: false, scrollPosition: UITableViewScrollPosition.None)
        }
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
    
    @IBAction func songViewPressed(sender: UIBarButtonItem) {
        performSegueWithIdentifier("ShowSpotifyTrackFromSongSelectionSegue", sender: nil)
    }
}
