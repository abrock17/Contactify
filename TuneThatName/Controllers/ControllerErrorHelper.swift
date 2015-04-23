import UIKit

class ControllerErrorHelper {
    
    class func displaySimpleAlertForTitle(title: String, andMessage message: String, onController controller: UIViewController) {
        let errorAlertViewController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "Dismiss", style: .Default, handler: nil)
        errorAlertViewController.addAction(okAction)
        controller.presentViewController(errorAlertViewController, animated: true, completion: nil)
    }
}