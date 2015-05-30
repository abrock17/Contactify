import UIKit

public class ControllerHelper {
    
    public init() {
    }
    
    public class func displaySimpleAlertForTitle(title: String, andMessage message: String, onController controller: UIViewController) {
        let errorAlertViewController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "Dismiss", style: .Default, handler: nil)
        errorAlertViewController.addAction(okAction)
        controller.presentViewController(errorAlertViewController, animated: true, completion: nil)
    }
    
    public class func displaySimpleAlertForTitle(title: String, andError error: NSError, onController controller: UIViewController) {
        displaySimpleAlertForTitle(title, andMessage: error.localizedDescription, onController: controller)
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
    
    public func getImageForURL(url: NSURL, completionHandler: UIImage? -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            var image: UIImage?
            let data = NSData(contentsOfURL: url)
            if let data = data {
                image = UIImage(data: data)
            } else {
                print("No image for url: \(url)")
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                completionHandler(image)
            }
        }
    }
}