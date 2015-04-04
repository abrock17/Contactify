import UIKit
import AddressBook

class CreatePlaylistController: UIViewController {
    
    var contactNames = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        addressBookSpike()
    }
    
    func addressBookSpike() {
        let addressBook: ABAddressBookRef! = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()
        
        switch (ABAddressBookGetAuthorizationStatus()) {
        case .Denied, .Restricted:
            println("access denied")
        case .Authorized:
            extractContactNames(addressBook)
        case .NotDetermined:
            ABAddressBookRequestAccessWithCompletion(addressBook) {
                (granted, error) in

                if granted {
                    self.extractContactNames(addressBook)
                } else {
                    println("access denied")
                }
            }
        }
    }
    
    func extractContactNames(addressBook: ABAddressBookRef) {
        let contacts: Array = ABAddressBookCopyArrayOfAllPeople(addressBook).takeRetainedValue()
        for contactRef: ABRecordRef in contacts {
            let firstName = ABRecordCopyValue(contactRef, kABPersonFirstNameProperty).takeRetainedValue() as? String
            let lastName = ABRecordCopyValue(contactRef, kABPersonLastNameProperty).takeRetainedValue() as? String
            println("contact: \(lastName), \(firstName)")
            if let firstName = firstName {
                contactNames.append(firstName)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let playlistTableViewController = segue.destinationViewController as PlaylistTableViewController
        playlistTableViewController.searchNames = contactNames
    }
    
}
