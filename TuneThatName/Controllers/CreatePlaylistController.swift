import UIKit

public class CreatePlaylistController: UIViewController {
    
    let minNumberOfSongs = 1
    let maxNumberOfSongs = 100
    
    var playlistPreferences: PlaylistPreferences!
    var playlist: Playlist?
    
    public var playlistService = PlaylistService()
    
    lazy var activityIndicator: UIActivityIndicatorView = ControllerHelper.newActivityIndicatorForView(self.view)

    @IBOutlet public weak var numberOfSongsSlider: UISlider!
    @IBOutlet public weak var numberOfSongsLabel: UILabel!
    @IBOutlet public weak var filterContactsSwitch: UISwitch!
    @IBOutlet public weak var selectNamesButton: UIButton!
    @IBOutlet public weak var favorPopularSwitch: UISwitch!
    @IBOutlet public weak var createPlaylistButton: UIButton!

    override public func viewDidLoad() {
        super.viewDidLoad()
        updateForPlaylistPreferences()

        // Do any additional setup after loading the view.
    }
    
    func updateForPlaylistPreferences() {
        if playlistPreferences == nil {
            playlistPreferences = PlaylistPreferences(numberOfSongs: 10, filterContacts: false, songPreferences: SongPreferences(favorPopular: true))
        }
        numberOfSongsSlider.value = (Float(playlistPreferences.numberOfSongs - minNumberOfSongs) / Float(maxNumberOfSongs - minNumberOfSongs))
        numberOfSongsLabel.text = String(playlistPreferences.numberOfSongs)
        updateSelectNamesButtonForFilterContacts(playlistPreferences.filterContacts)
        filterContactsSwitch.on = playlistPreferences.filterContacts
        favorPopularSwitch.on = playlistPreferences.songPreferences.favorPopular
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation

    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let spotifyPlaylistTableController = segue.destinationViewController as? SpotifyPlaylistTableController {
            spotifyPlaylistTableController.playlist = self.playlist
        }
    }
    
    @IBAction public func numberOfSongsValueChanged(sender: UISlider) {
        playlistPreferences.numberOfSongs = Int(round(sender.value * Float(maxNumberOfSongs - minNumberOfSongs))) + minNumberOfSongs
        numberOfSongsLabel.text = String(playlistPreferences.numberOfSongs)
    }
    
    @IBAction public func filterContactsStateChanged(sender: UISwitch) {
        playlistPreferences.filterContacts = sender.on
        updateSelectNamesButtonForFilterContacts(playlistPreferences.filterContacts)
    }
    
    func updateSelectNamesButtonForFilterContacts(filterContacts: Bool) {
        selectNamesButton.enabled = filterContacts
        selectNamesButton.setTitle(filterContacts ? "Select Names" : "Select Names (Using All)", forState: UIControlState.Normal)
    }
    
    @IBAction public func selectNamesPressed(sender: UIButton) {
        self.performSegueWithIdentifier("SelectNamesSegue", sender: sender)
    }
    
    @IBAction public func favorPopularStateChanged(sender: UISwitch) {
        playlistPreferences.songPreferences.favorPopular = sender.on
    }
    
    @IBAction public func createPlaylistPressed(sender: AnyObject) {
        ControllerHelper.handleBeginBackgroundActivityForView(view, activityIndicator: activityIndicator)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.playlistService.createPlaylistWithPreferences(self.playlistPreferences) {
                playlistResult in
                
                dispatch_async(dispatch_get_main_queue()) {
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
    }
    
    func handleCreatedPlaylist(playlist: Playlist, sender: AnyObject) {
        println("Playlist: \(playlist)")
        self.playlist = playlist
        self.performSegueWithIdentifier("CreatePlaylistSegue", sender: sender)
    }
    
    @IBAction public func unwindToCreatePlaylist(sender: UIStoryboardSegue) {
    }
}
