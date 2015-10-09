import UIKit

public class PlaylistNameEntryController: UIAlertController {

    public convenience init(currentName: String?, completionHandler: String -> Void) {
        self.init()
        self.init(title: "Name Your Playlist", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        addTextFieldWithName(currentName, andActionsWithHandler: completionHandler)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addTextFieldWithName(name: String?, andActionsWithHandler completionHandler: String -> Void) {
        addTextFieldWithConfigurationHandler() {
            textField in
            
            textField.text = name
            textField.placeholder = "Playlist Name"
            textField.clearButtonMode = UITextFieldViewMode.WhileEditing
            textField.addTarget(self, action: "playlistNameTextFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        addAction(cancelAction)

        let okAction = UIAlertAction(title: "Done", style: UIAlertActionStyle.Default) {
            alertAction in
            
            completionHandler((self.textFields?.first?.text)!)
        }
        okAction.enabled = (name != nil)
        addAction(okAction)
    }
    
    func playlistNameTextFieldDidChange(sender: UITextField) {
        actions.last!.enabled = !sender.text!.isEmpty
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
