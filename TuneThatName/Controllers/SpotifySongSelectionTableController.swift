import UIKit

public class SpotifySongSelectionTableController: UITableViewController {
    
    public var searchContact: Contact!
    public var songSelectionCompletionHandler: ((Song, Contact?) -> Void)!
    public var songs = [Song]()
    
    public var echoNestService = EchoNestService()
    public var preferencesService = PreferencesService()
    
    lazy var activityIndicator: UIActivityIndicatorView = ControllerHelper.newActivityIndicatorForView(self.navigationController!.view)
    
    @IBOutlet public weak var doneButton: UIBarButtonItem!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        doneButton.enabled = false
        populateSongs()
    }
    
    func populateSongs() {
        var playlistPreferences = preferencesService.retrievePlaylistPreferences()
        if playlistPreferences == nil {
            playlistPreferences = preferencesService.getDefaultPlaylistPreferences()
        }
        
        ControllerHelper.handleBeginBackgroundActivityForView(view, activityIndicator: activityIndicator)
        echoNestService.findSongs(titleSearchTerm: searchContact.firstName!, songPreferences: playlistPreferences!.songPreferences, desiredNumberOfSongs: 20) {
            songResult in
            
            switch (songResult) {
            case .Success(let songs):
                self.songs = songs
                self.tableView.reloadData()
            case .Failure(let error):
                ControllerHelper.displaySimpleAlertForTitle("Error Searching for Songs", andError: error, onController: self) {
                    alertAction in
                    
                    self.navigationController?.popViewControllerAnimated(true)
                }
            }
            ControllerHelper.handleCompleteBackgroundActivityForView(self.view, activityIndicator: self.activityIndicator)
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
    
    @IBAction func cancelPressed(sender: UIBarButtonItem) {
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func donePressed(sender: UIBarButtonItem) {
        let selectedSong = songs[tableView.indexPathForSelectedRow!.row]
        songSelectionCompletionHandler(selectedSong, searchContact)
    }
}
