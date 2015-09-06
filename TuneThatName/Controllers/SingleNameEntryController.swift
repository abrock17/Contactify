import UIKit

public class SingleNameEntryController: UIAlertController {
    
    public convenience init(completionHandler: Contact -> Void) {
        self.init()
        self.init(title: "Choose a Name", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
