//
//  CreatePlaylistHelpControllerViewController.swift
//  TuneThatName
//
//  Created by Tony Brock on 12/9/15.
//  Copyright © 2015 Tony Brock. All rights reserved.
//

import UIKit

class CreatePlaylistHelpController: UIViewController {

    @IBOutlet weak var helpSubView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        addGradient()
    }
    
    func addGradient() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.blackColor().CGColor, UIAppearanceManager.barBackground.CGColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = helpSubView.bounds
        helpSubView.layer.insertSublayer(gradientLayer, atIndex: 0)
    }
    
    override func didReceiveMemoryWarning() {
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
