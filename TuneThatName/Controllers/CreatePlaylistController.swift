import UIKit

public class CreatePlaylistController: UIViewController {
    
    let minNumberOfSongs = 1
    let maxNumberOfSongs = 50
    
    var playlistPreferences: PlaylistPreferences!
    var playlist: Playlist?
    
    public var playlistService = PlaylistService()
    public var preferencesService = PreferencesService()
    public var notificationCenter = NSNotificationCenter.defaultCenter()
    
    lazy var activityIndicator: UIActivityIndicatorView = ControllerHelper.newActivityIndicatorForView(self.navigationController!.view)

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
    @IBOutlet public weak var createPlaylistButton: UIButton!

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
            playlistPreferences = PlaylistPreferences(numberOfSongs: 10, filterContacts: false, songPreferences: SongPreferences(characteristics: [.Popular]))
        }
        numberOfSongsChanged()
        selectNamesButton.enabled = playlistPreferences.filterContacts
        filterContactsSwitch.on = playlistPreferences.filterContacts
        favorPopularSwitch.on = contains(playlistPreferences.songPreferences.characteristics, .Popular)
        favorPositiveSwitch.on = contains(playlistPreferences.songPreferences.characteristics, .Positive)
        favorNegativeSwitch.on = contains(playlistPreferences.songPreferences.characteristics, .Negative)
        favorEnergeticSwitch.on = contains(playlistPreferences.songPreferences.characteristics, .Energetic)
        favorChillSwitch.on = contains(playlistPreferences.songPreferences.characteristics, .Chill)
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
