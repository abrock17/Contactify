import UIKit

public class ControllerHelper {
    
    public class func displaySimpleAlertForTitle(title: String, andMessage message: String, onController controller: UIViewController) {
        let errorAlertViewController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "Dismiss", style: .Default, handler: nil)
        errorAlertViewController.addAction(okAction)
        controller.presentViewController(errorAlertViewController, animated: true, completion: nil)
    }
    
    public class func newActivityIndicatorForView(view: UIView) -> UIActivityIndicatorView {
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        view.addSubview(indicator)
        indicator.center = CGPointMake(view.frame.size.width / 2.0, view.frame.size.height / 2.0)
        indicator.hidesWhenStopped = true
        return indicator
    }
    
    public class func handleBeginBackgroundActivityForView(view: UIView, activityIndicator: UIActivityIndicatorView) {
        view.userInteractionEnabled = false
        activityIndicator.startAnimating()
    }
    
    public class func handleCompleteBackgroundActivityForView(view: UIView, activityIndicator: UIActivityIndicatorView) {
        view.userInteractionEnabled = true
        activityIndicator.stopAnimating()
    }
}