import UIKit

public class ControllerHelper {
    
    public init() {
    }
    
    public class func displaySimpleAlertForTitle(title: String, andMessage message: String, onController controller: UIViewController) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: nil))
        controller.presentViewController(alertController, animated: true, completion: nil)
    }
    
    public class func displaySimpleAlertForTitle(title: String, andError error: NSError, onController controller: UIViewController) {
        displaySimpleAlertForTitle(title, andMessage: error.localizedDescription, onController: controller)
    }
    
    public class func newActivityIndicatorForView(view: UIView) -> UIActivityIndicatorView {
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        view.addSubview(indicator)
        indicator.bounds = view.frame
        indicator.layer.backgroundColor = UIColor(white: 0.0, alpha: 0.3).CGColor
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