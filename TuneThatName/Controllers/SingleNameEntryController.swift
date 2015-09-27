import UIKit

public class SingleNameEntryController: UIViewController {

    public var contact = Contact(id: -1, firstName: nil, lastName: nil)
    var allConctacts = [Contact]()
    public var songSelectionCompletionHandler: ((Song, Contact?) -> Void)!
    
    public var contactService = ContactService()
    
    @IBOutlet public weak var nameEntryTextField: UITextField!
    @IBOutlet public weak var doneButton: UIBarButtonItem!
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        nameEntryTextChanged(nameEntryTextField)
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
    

    // MARK: - Navigation

    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let spotifySongSelectionTableController = segue.destinationViewController as? SpotifySongSelectionTableController {
            spotifySongSelectionTableController.searchContact = contact
            spotifySongSelectionTableController.songSelectionCompletionHandler = songSelectionCompletionHandler
        }
    }
    
    @IBAction public func nameEntryTextChanged(sender: UITextField) {
        doneButton.enabled = !nameEntryTextField.text
            .stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).isEmpty
    }
    
    @IBAction public func cancelPressed(sender: UIBarButtonItem) {
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction public func donePressed(sender: UIBarButtonItem) {
        contact = Contact(
            id: -1,
            firstName: nameEntryTextField.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()),
            lastName: nil)
        performSegueWithIdentifier("SelectSongDifferentContactSegue", sender: sender)
    }
}
