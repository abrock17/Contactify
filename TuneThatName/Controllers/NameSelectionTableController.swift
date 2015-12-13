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
    
    public var selectAllButton: UIBarButtonItem!
    public var selectNoneButton: UIBarButtonItem!

    override public func viewDidLoad() {
        super.viewDidLoad()
        addMassSelectionButtons()
        populateContacts()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    func addMassSelectionButtons() {
        selectAllButton = UIBarButtonItem(title: "All", style: UIBarButtonItemStyle.Plain, target: self, action: "selectAllPressed:")
        selectNoneButton = UIBarButtonItem(title: "None", style: UIBarButtonItemStyle.Plain, target: self, action: "selectNonePressed:")
        navigationItem.rightBarButtonItems = [selectNoneButton, selectAllButton]
    }

    func populateContacts() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.contactService.retrieveAllContacts() {
                contactListResult in
                
                switch(contactListResult) {
                case .Success(let contacts):
                    self.buildContactSectionMap(contacts)
                    self.contactService.retrieveFilteredContacts() {
                        contactListResult in
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            switch(contactListResult) {
                            case .Success(let contacts):
                                self.filteredContacts = Set<Contact>(contacts)
                                if self.filteredContacts.isEmpty {
                                    self.selectAllPressed(self.selectAllButton)
                                }
                                self.tableView.reloadData()
                            case .Failure(let error):
                                self.handleFilteredContactRetrievalError(error)
                            }
                        }
                    }
                case .Failure(let error):
                    self.handleAllContactRetrievalError(error)
                }
            }
        }
    }
    
    func buildContactSectionMap(contacts: [Contact]) {
        for contact in contacts {
            var added = false
            for indexTitle in indexTitles {
                if contact.fullName.uppercaseString.hasPrefix(indexTitle) {
                    addToContactSectionMapForKey(indexTitle, withContact: contact)
                    added = true
                    break
                }
            }
            if !added {
                addToContactSectionMapForKey("#", withContact: contact)
            }
        }
        for key in contactSectionMap.keys {
            contactSectionMap[key]!.sortInPlace({ $0.fullName < $1.fullName })
        }
    }
    
    func addToContactSectionMapForKey(key: String, withContact contact: Contact) {
        if contactSectionMap[key] == nil {
            contactSectionMap[key] = [Contact]()
        }
        contactSectionMap[key]?.append(contact)
    }
    
    func handleAllContactRetrievalError(error: NSError) {
        dispatch_async(dispatch_get_main_queue()) {
            print("Error retrieving all contacts: \(error)")
            ControllerHelper.displaySimpleAlertForTitle("Unable to Retrieve Your Contacts",
                andError: error, onController: self) {
                action in
                
                self.navigationController?.popViewControllerAnimated(true)
            }
        }
    }
    
    func handleFilteredContactRetrievalError(error: NSError) {
        dispatch_async(dispatch_get_main_queue()) {
            print("Error retrieving filtered contacts: \(error)")
            ControllerHelper.displaySimpleAlertForTitle("Unable to Retrieve Your Selected Names",
                andError: error, onController: self)
        }
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return indexTitles.count
    }
    
    override public func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        return indexTitles
    }
    
    override public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let indexTitle = indexTitles[section]
        return contactSectionMap.keys.contains(indexTitle) ? indexTitle : nil
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
        let cell = tableView.dequeueReusableCellWithIdentifier("ContactNameTableCell", forIndexPath: indexPath)
        
        let contact = contactForIndexPath(indexPath)
        
        let fontSize = cell.textLabel!.font.pointSize
        let attributedNameText = NSMutableAttributedString(string: contact.fullName, attributes: [NSFontAttributeName: UIFont.systemFontOfSize(fontSize)])
        attributedNameText.addAttribute(NSFontAttributeName, value: UIFont.boldSystemFontOfSize(fontSize),
            range: (contact.fullName as NSString).rangeOfString(contact.searchString))
        cell.textLabel?.attributedText = attributedNameText

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
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        contactService.saveFilteredContacts(Array<Contact>(filteredContacts))
    }
    
    func selectAllPressed(sender: UIBarButtonItem) {
        var allContacts = [Contact]()
        for contacts in contactSectionMap.values {
            allContacts += contacts
        }
        filteredContacts = Set<Contact>(allContacts)
        tableView.reloadData()
    }
    
    func selectNonePressed(sender: UIBarButtonItem) {
        filteredContacts.removeAll(keepCapacity: false)
        tableView.reloadData()
    }
}
