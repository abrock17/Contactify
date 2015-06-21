import UIKit

public class NameSelectionTableController: UITableViewController {
    
    var indexTitles: [String] = {
        var indexTitles = (65...90).map({ String(UnicodeScalar($0)) })
        indexTitles.append("#")
        return indexTitles
    }()
    var contactSectionMap = [String:[Contact]]()
    var filteredContacts = Set<Contact>()

    public var contactService = ContactService()

    override public func viewDidLoad() {
        super.viewDidLoad()
        contactService.retrieveAllContacts() {
            contactListResult in
            
            switch(contactListResult) {
            case .Success(let contacts):
                self.buildContactSectionMap(contacts)
            case .Failure(let error):
                println("Error retrieving contacts: \(error)")
            }
        }

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    func buildContactSectionMap(contacts: [Contact]) {
        for contact in contacts {
            var added = false
            for indexTitle in indexTitles {
                if contact.fullName.uppercaseString.hasPrefix(indexTitle) {
                    addToContactSectionMap(key: indexTitle, contact: contact)
                    added = true
                    break
                }
            }
            if !added {
                addToContactSectionMap(key: "#", contact: contact)
            }
        }
        for key in contactSectionMap.keys {
            contactSectionMap[key]!.sort({ $0.fullName < $1.fullName })
        }
    }
    
    func addToContactSectionMap(#key: String, contact: Contact) {
        if contactSectionMap[key] == nil {
            contactSectionMap[key] = [Contact]()
        }
        contactSectionMap[key]?.append(contact)
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return indexTitles.count
    }
    
    override public func sectionIndexTitlesForTableView(tableView: UITableView) -> [AnyObject]! {
        return indexTitles
    }
    
    override public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let indexTitle = indexTitles[section]
        return contains(contactSectionMap.keys, indexTitle) ? indexTitle : nil
    }
    
    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numberOfRows: Int
        if let contacts = contactsForSection(section) {
            numberOfRows = contacts.count
        } else {
            numberOfRows = 0
        }
        
        return numberOfRows
    }

    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ContactNameTableCell", forIndexPath: indexPath) as! UITableViewCell
        let contact = contactForIndexPath(indexPath)
        cell.textLabel?.text = contact.fullName
        if filteredContacts.contains(contact) {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.None
        }

        return cell
    }
    
    override public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        let contact = contactForIndexPath(indexPath)
        if filteredContacts.contains(contact) {
            filteredContacts.remove(contact)
        } else {
            filteredContacts.insert(contact)
        }
        
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
    }

    func contactsForSection(section: Int) -> [Contact]? {
        let sectionTitle = indexTitles[section]
        return contactSectionMap[sectionTitle]
    }
    
    func contactForIndexPath(indexPath: NSIndexPath) -> Contact {
        let contacts = contactsForSection(indexPath.section)
        return contacts![indexPath.row]
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

}
