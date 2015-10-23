import UIKit

public class ControllerHelper {
    
    static let barButtonWidth: CGFloat = 29
    
    public init() {
    }
    
    public class func displaySimpleAlertForTitle(title: String, andMessage message: String, onController controller: UIViewController, withHandler handler: ((UIAlertAction!) -> Void)! = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: handler))
        controller.presentViewController(alertController, animated: true, completion: nil)
    }
    
    public class func displaySimpleAlertForTitle(title: String, andError error: NSError, onController controller: UIViewController, withHandler handler: ((UIAlertAction!) -> Void)! = nil) {
        displaySimpleAlertForTitle(title, andMessage: error.localizedDescription, onController: controller, withHandler: handler)
    }
    
    public class func newActivityIndicatorForView(view: UIView) -> UIActivityIndicatorView {
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        view.addSubview(indicator)
        indicator.frame = view.bounds
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
    
    public class func getIndexForSpotifyTrack(spotifyTrack: SpotifyTrack?, inSongs songs: [Song]) -> Int? {
        var indexForURI: Int?
        if let uri = spotifyTrack?.uri {
            for (index, song) in songs.enumerate() {
                if song.uri == uri {
                    indexForURI = index
                    break
                }
            }
        }
        
        return indexForURI
    }
    
    public class func createPlayPauseButtonForTarget(target: UIViewController, withAction action: Selector, andIsPlaying isPlaying: Bool) -> UIBarButtonItem {
        let buttonSystemItem = isPlaying ? UIBarButtonSystemItem.Pause : UIBarButtonSystemItem.Play
        return UIBarButtonItem(barButtonSystemItem: buttonSystemItem, target: target, action: action)
    }
    
    public class func updatePlayPauseButtonOnTarget(target: UIViewController, withAction action: Selector, forIsPlaying isPlaying: Bool) {
        target.toolbarItems?.removeLast()
        target.toolbarItems?.append(createPlayPauseButtonForTarget(target, withAction: action, andIsPlaying: isPlaying))
    }
    
    public class func updateBarButtonItemOnTarget(target: UIViewController, action: Selector, atToolbarIndex index: Int, withImage image: UIImage?) {
        let imageButton: UIButton
        if let image = image {
            imageButton = UIButton(frame: CGRectMake(0, 0, barButtonWidth, barButtonWidth))
            imageButton.setBackgroundImage(image, forState: UIControlState.Normal)
        } else {
            imageButton = UIButton()
            imageButton.enabled = false
        }
        imageButton.addTarget(target, action: action, forControlEvents: UIControlEvents.TouchUpInside)
        target.toolbarItems?.removeAtIndex(index)
        target.toolbarItems?.insert(UIBarButtonItem(customView: imageButton), atIndex: index)
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