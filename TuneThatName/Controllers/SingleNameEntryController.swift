import UIKit

public class SingleNameEntryController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    public var selectedContact: Contact?
    var allConctacts = [Contact]()
    var suggestedContacts = [Contact]()
    public var songSelectionCompletionHandler: ((Song, Contact?) -> Void)!
    
    public var contactService = ContactService()
    
    @IBOutlet public weak var nameEntryTextField: UITextField!
    @IBOutlet public weak var lastNameLabel: UILabel!
    @IBOutlet public weak var nameSuggestionTableView: UITableView!
    @IBOutlet public weak var doneButton: UIBarButtonItem!
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        nameEntryTextChanged(nameEntryTextField)
        nameSuggestionTableView.hidden = true
        
        contactService.retrieveAllContacts() {
            contactListResult in
            
            switch(contactListResult) {
            case .Success(let contacts):
                self.allConctacts = contacts
            case .Failure(let error):
                println("Unable to retrieve contacts: \(error)")
            }
        }
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override public func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        nameEntryTextField.becomeFirstResponder()
    }
    

    // MARK: - Navigation

    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let spotifySongSelectionTableController = segue.destinationViewController as? SpotifySongSelectionTableController {
            spotifySongSelectionTableController.searchContact = selectedContact
            spotifySongSelectionTableController.songSelectionCompletionHandler = songSelectionCompletionHandler
        }
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return suggestedContacts.count
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("NameSuggestionTableCell", forIndexPath: indexPath) as! UITableViewCell
        
        let contact = suggestedContacts[indexPath.row]
        cell.textLabel?.text = contact.fullName

        return cell
    }
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedContact = suggestedContacts[indexPath.row]
        nameSuggestionTableView.hidden = true
        setNameEntryTextAndLastNameLabelForSelectedContact()
    }
    
    func setNameEntryTextAndLastNameLabelForSelectedContact() {
        let firstName = selectedContact!.firstName ?? ""
        let lastName = selectedContact!.lastName ?? ""
        nameEntryTextField.text = firstName
        if firstName.isEmpty {
            nameEntryTextField.text = lastName
            lastNameLabel.text = ""
        } else {
            lastNameLabel.text = lastName.isEmpty ? "" : "(\(lastName))"
        }
    }
    
    @IBAction public func nameEntryTextChanged(sender: UITextField) {
        let trimmedText = nameEntryTextField.text
            .stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        doneButton.enabled = !trimmedText.isEmpty
        
        selectedContact = nil
        lastNameLabel.text = ""
        
        reloadNameSuggestionTableViewForText(trimmedText)
    }
    
    func reloadNameSuggestionTableViewForText(text: String) {
        suggestedContacts.removeAll(keepCapacity: false)
        if !text.isEmpty {
            for contact in allConctacts {
                let contactWords = (split(contact.fullName) { $0 == " " })
                    .map({ $0.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) })
                let matchingWords = contactWords.filter({ $0.lowercaseString.hasPrefix(text) })
                if !matchingWords.isEmpty {
                    suggestedContacts.append(contact)
                }
            }
        }
        
        suggestedContacts.sort({ $0.fullName < $1.fullName })
        nameSuggestionTableView.hidden = suggestedContacts.isEmpty
        nameSuggestionTableView.reloadData()
    }
    
    @IBAction public func cancelPressed(sender: UIBarButtonItem) {
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction public func donePressed(sender: UIBarButtonItem) {
        if selectedContact == nil {
            selectedContact = Contact(id: -1,
                firstName: nameEntryTextField.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()),
                lastName: nil)
        }
        performSegueWithIdentifier("SelectSongDifferentContactSegue", sender: sender)
    }
}
