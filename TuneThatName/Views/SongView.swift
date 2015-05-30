import UIKit

public class SongView: UIView {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

    @IBOutlet public weak var image: UIImageView!
    @IBOutlet public weak var title: UILabel!
    @IBOutlet public weak var artist: UILabel!
    @IBOutlet public weak var album: UILabel!
    @IBOutlet public weak var closeButton: UIButton!
    
    @IBAction func close(sender: AnyObject) {
        self.removeFromSuperview()
    }
}
