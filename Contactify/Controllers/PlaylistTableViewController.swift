import UIKit

class PlaylistTableViewController: UITableViewController, SPTAuthViewDelegate {
    
    var authViewController: SPTAuthViewController!
    var songDataList = [SongData]()
    
    let echoNestService = EchoNestService()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        loadSongDataList()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(false, animated: animated)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setToolbarHidden(true, animated: animated)
    }
    
    func loadSongDataList() {
        let names = ["John", "Paul", "George", "Ringo"]
        var retrievalCompleted = 0
        for name in names {
            echoNestService.findSongData(titleSearchTerm: name,
                completionHandler: {(songDataResult: EchoNestService.SongDataResult) -> Void in
                    
                    retrievalCompleted++
                    
                    switch (songDataResult) {
                    case .Success(let songData):
                        if let songData = songData {
                            self.songDataList.append(songData)
                            if names.count == retrievalCompleted {
                                self.tableView.reloadData()
                            }
                        }
                        println("song title: \(songData?.title)")
                    case .Failure(let error):
                        println("error: \(error)")
                    }
            })
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return songDataList.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("PlaylistTableCell", forIndexPath: indexPath) as UITableViewCell

        let songData = songDataList[indexPath.row]
        cell.textLabel?.text = songData.title
        cell.detailTextLabel?.text = songData.artistName

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
    
    @IBAction func savePlaylist(sender: AnyObject) {
        openLogin()
    }
    
    func openLogin() {
        authViewController = SPTAuthViewController.authenticationViewController()
        authViewController.delegate = self
        authViewController.modalPresentationStyle = UIModalPresentationStyle.CurrentContext
        authViewController.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        
        self.modalPresentationStyle = UIModalPresentationStyle.CurrentContext
        self.definesPresentationContext = true
        
        presentViewController(self.authViewController, animated: false, completion: nil)
    }
    
    func authenticationViewController(viewController: SPTAuthViewController, didFailToLogin error: NSError) {
        println("Login failed... error: \(error)")
    }
    
    func authenticationViewController(viewController: SPTAuthViewController, didLoginWithSession session: SPTSession) {
        println("Login succeeded... session: \(session)")
    }
    
    func authenticationViewControllerDidCancelLogin(viewController: SPTAuthViewController) {
        println("Login cancelled")
    }
}
