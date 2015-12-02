import UIKit

public class CreatePlaylistController: UIViewController {
    
    let minNumberOfSongs = 1
    let maxNumberOfSongs = 50
    
    var playlistPreferences: PlaylistPreferences!
    var playlist: Playlist?
    
    public var playlistService = PlaylistService()
    public var preferencesService = PreferencesService()
    public var notificationCenter = NSNotificationCenter.defaultCenter()
    
    lazy var activityIndicator: UIView = NSBundle.mainBundle().loadNibNamed("PlaylsitCreationActivityIndicator", owner: self, options: nil).first as! UIView

    @IBOutlet public weak var numberOfSongsSlider: UISlider!
    @IBOutlet public weak var numberOfSongsLabel: UILabel!
    @IBOutlet public weak var incrementNumberOfSongsButton: UIButton!
    @IBOutlet public weak var decrementNumberOfSongsButton: UIButton!
    @IBOutlet public weak var filterContactsSwitch: UISwitch!
    @IBOutlet public weak var selectNamesButton: UIButton!
    @IBOutlet public weak var favorPopularSwitch: UISwitch!
    @IBOutlet public weak var favorPositiveSwitch: UISwitch!
    @IBOutlet public weak var favorNegativeSwitch: UISwitch!
    @IBOutlet public weak var favorEnergeticSwitch: UISwitch!
    @IBOutlet public weak var favorChillSwitch: UISwitch!
    @IBOutlet public weak var createPlaylistButton: UIBarButtonItem!

    override public func viewDidLoad() {
        super.viewDidLoad()
        updateForPlaylistPreferences()
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        notificationCenter.addObserver(self, selector: "savePlaylistPreferences", name: UIApplicationWillResignActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: "savePlaylistPreferences", name: UIApplicationWillTerminateNotification, object: nil)
    }
    
    override public func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        savePlaylistPreferences()
        notificationCenter.removeObserver(self)
    }
    
    func savePlaylistPreferences() {
        preferencesService.savePlaylistPreferences(playlistPreferences)
    }

    func updateForPlaylistPreferences() {
        playlistPreferences = preferencesService.retrievePlaylistPreferences()
        if playlistPreferences == nil {
            playlistPreferences = preferencesService.getDefaultPlaylistPreferences()
        }
        numberOfSongsChanged()
        selectNamesButton.enabled = playlistPreferences.filterContacts
        filterContactsSwitch.on = playlistPreferences.filterContacts
        favorPopularSwitch.on = playlistPreferences.songPreferences.characteristics.contains(.Popular)
        favorPositiveSwitch.on = playlistPreferences.songPreferences.characteristics.contains(.Positive)
        favorNegativeSwitch.on = playlistPreferences.songPreferences.characteristics.contains(.Negative)
        favorEnergeticSwitch.on = playlistPreferences.songPreferences.characteristics.contains(.Energetic)
        favorChillSwitch.on = playlistPreferences.songPreferences.characteristics.contains(.Chill)
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
    
    @IBAction func incrementNumberOfSongsPressed(sender: UIButton) {
        if playlistPreferences.numberOfSongs < maxNumberOfSongs {
            playlistPreferences.numberOfSongs++
            numberOfSongsChanged()
        }
    }
    
    @IBAction func decrementNumberOfSongsPressed(sender: UIButton) {
        if playlistPreferences.numberOfSongs > minNumberOfSongs {
            playlistPreferences.numberOfSongs--
            numberOfSongsChanged()
        }
    }
    
    func numberOfSongsChanged() {
        numberOfSongsSlider.value = (Float(playlistPreferences.numberOfSongs - minNumberOfSongs) / Float(maxNumberOfSongs - minNumberOfSongs))
        numberOfSongsLabel.text = String(playlistPreferences.numberOfSongs)
    }
    
    @IBAction public func numberOfSongsValueChanged(sender: UISlider) {
        playlistPreferences.numberOfSongs = Int(round(sender.value * Float(maxNumberOfSongs - minNumberOfSongs))) + minNumberOfSongs
        numberOfSongsLabel.text = String(playlistPreferences.numberOfSongs)
    }
    
    @IBAction public func filterContactsStateChanged(sender: UISwitch) {
        playlistPreferences.filterContacts = sender.on
        selectNamesButton.enabled = playlistPreferences.filterContacts
        if playlistPreferences.filterContacts {
            self.performSegueWithIdentifier("SelectNamesSegue", sender: nil)
        }
    }
        
    @IBAction public func selectNamesPressed(sender: UIButton) {
        self.performSegueWithIdentifier("SelectNamesSegue", sender: sender)
    }
    
    @IBAction public func favorPopularStateChanged(sender: UISwitch) {
        updateSongPreferences(playlistPreferences.songPreferences,
            forCharacteristic: SongPreferences.Characteristic.Popular, andSwitchValue: sender.on)
    }
    
    @IBAction public func favorPositiveStateChanged(sender: UISwitch) {
        updateSongPreferences(playlistPreferences.songPreferences,
            forCharacteristic: SongPreferences.Characteristic.Positive, andSwitchValue: sender.on)
        favorNegativeSwitch.on = false
        updateSongPreferences(playlistPreferences.songPreferences,
            forCharacteristic: SongPreferences.Characteristic.Negative, andSwitchValue: false)
    }
    
    @IBAction public func favorNegativeStateChanged(sender: UISwitch) {
        updateSongPreferences(playlistPreferences.songPreferences,
            forCharacteristic: SongPreferences.Characteristic.Negative, andSwitchValue: sender.on)
        favorPositiveSwitch.on = false
        updateSongPreferences(playlistPreferences.songPreferences,
            forCharacteristic: SongPreferences.Characteristic.Positive, andSwitchValue: false)
    }
    
    @IBAction public func favorEnergeticStateChanged(sender: UISwitch) {
        updateSongPreferences(playlistPreferences.songPreferences,
            forCharacteristic: SongPreferences.Characteristic.Energetic, andSwitchValue: sender.on)
        favorChillSwitch.on = false
        updateSongPreferences(playlistPreferences.songPreferences,
            forCharacteristic: SongPreferences.Characteristic.Chill, andSwitchValue: false)
    }
    
    @IBAction public func favorChillStateChanged(sender: UISwitch) {
        updateSongPreferences(playlistPreferences.songPreferences,
            forCharacteristic: SongPreferences.Characteristic.Chill, andSwitchValue: sender.on)
        favorEnergeticSwitch.on = false
        updateSongPreferences(playlistPreferences.songPreferences,
            forCharacteristic: SongPreferences.Characteristic.Energetic, andSwitchValue: false)
    }
    
    func updateSongPreferences(songPreferences: SongPreferences, forCharacteristic characteristic: SongPreferences.Characteristic, andSwitchValue switchValue: Bool) {
        if switchValue {
            songPreferences.characteristics.insert(characteristic)
        } else {
            songPreferences.characteristics.remove(characteristic)
        }
    }
    
    @IBAction public func createPlaylistPressed(sender: UIBarButtonItem) {
        activityIndicator.frame = self.navigationController!.view.bounds
        self.view.addSubview(activityIndicator)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.playlistService.createPlaylistWithPreferences(self.playlistPreferences) {
                playlistResult in
                
                dispatch_async(dispatch_get_main_queue()) {
                    switch (playlistResult) {
                    case .Failure(let error):
                        print("Error creating playlist: \(error)")
                        ControllerHelper.displaySimpleAlertForTitle("Unable to Create Your Playlist", andError: error, onController: self)
                    case .Success(let playlist):
                        self.handleCreatedPlaylist(playlist, sender: sender)
                    }
                    self.activityIndicator.removeFromSuperview()
                }
            }
        }
    }
    
    func handleCreatedPlaylist(playlist: Playlist, sender: AnyObject) {
        print("Playlist: \(playlist)")
        self.playlist = playlist
        self.performSegueWithIdentifier("CreatePlaylistSegue", sender: sender)
    }
    
    @IBAction public func spotifyActionsPressed(sender: AnyObject) {
        let spotifyActionSheet = SpotifyActionSheetController(presentingView: (sender as! UIView),
            application: UIApplication.sharedApplication(), spotifyAuthService: SpotifyAuthService())

        presentViewController(spotifyActionSheet, animated: true, completion: nil)
    }
    
    @IBAction public func unwindToCreatePlaylist(sender: UIStoryboardSegue) {
    }
}
