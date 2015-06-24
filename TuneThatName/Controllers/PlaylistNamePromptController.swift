import UIKit

public protocol PlaylistNamePromptCompletionDelegate {
    
    func completedSuccessfullyWithPlaylistName(playlistName: String)
}

public class PlaylistNamePromptController: UIAlertController {

    var completionDelegate: PlaylistNamePromptCompletionDelegate?
    
    public convenience init(completionDelegate: PlaylistNamePromptCompletionDelegate) {
        self.init()
        self.init(title: "Name Your Playlist", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        self.completionDelegate = completionDelegate
        addActionsAndTextField()
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addActionsAndTextField() {
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) {
            (alertAction) in
            
            self.completionDelegate?.completedSuccessfullyWithPlaylistName((self.textFields?.first as! UITextField).text)
        }
        okAction.enabled = false
        addTextFieldWithConfigurationHandler() {
            textField in
            
            textField.placeholder = "Playlist Name"
            textField.addTarget(self, action: "playlistNameTextFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
        }
        
        addAction(cancelAction)
        addAction(okAction)
    }
    
    func playlistNameTextFieldDidChange(sender: UITextField) {
        let okAction = actions.last as! UIAlertAction
        let playlistNameTextField = textFields!.first as! UITextField
        okAction.enabled = !playlistNameTextField.text.isEmpty
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
