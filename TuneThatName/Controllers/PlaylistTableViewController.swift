import UIKit

public class PlaylistTableViewController: UITableViewController, SPTAuthViewDelegate {
    
    var playlist = Playlist(name: "Tune That Name")
    
    public var spotifyAuth: SPTAuth! = SPTAuth.defaultInstance()
    var authViewController: SPTAuthViewController!
    
    var echoNestService = EchoNestService()
    var spotifyService = SpotifyService()

    @IBOutlet public weak var saveButton: UIBarButtonItem!
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        loadPlaylistSongs()
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(false, animated: animated)
    }

    override public func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setToolbarHidden(true, animated: animated)
    }
    
    func loadPlaylistSongs() {
        let names = ["John", "Paul", "George", "Ringo"]
        var retrievalCompleted = 0
        for name in names {
            echoNestService.findSong(titleSearchTerm: name,
                completionHandler: {(songResult: EchoNestService.SongResult) -> Void in
                    
                    retrievalCompleted++
                    
                    switch (songResult) {
                    case .Success(let song):
                        if let song = song {
                            self.playlist.songs.append(song)
                            if names.count == retrievalCompleted {
                                self.tableView.reloadData()
                            }
                        }
                        println("song title: \(song?.title)")
                    case .Failure(let error):
                        println("error: \(error)")
                    }
            })
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
        var cell = tableView.dequeueReusableCellWithIdentifier("PlaylistTableCell", forIndexPath: indexPath) as UITableViewCell

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
    
    
    @IBAction public func savePlaylistClicked(sender: AnyObject) {
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
        let session = spotifyAuth.session
        println("access token: \(session?.accessToken)")
        spotifyService.savePlaylist(playlist, session: session) {
            playlistResult in
            
            switch (playlistResult) {
            case .Success(let playlist):
                self.playlist = playlist
                println("playlist: \(playlist.name), \(playlist.songs.count) songs")
                for song in playlist.songs {
                    println("song : \(song.title), \(song.artistName), \(song.uri?.absoluteString)")
                }
            case .Failure(let error):
                println("error: \(error)")
            }
        }
    }
}