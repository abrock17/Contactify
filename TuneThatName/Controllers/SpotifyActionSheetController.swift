//
//  SpotifyActionSheetController.swift
//  TuneThatName
//
//  Created by Tony Brock on 11/18/15.
//  Copyright © 2015 Tony Brock. All rights reserved.
//

import UIKit

public class SpotifyActionSheetController: UIAlertController {
    
    var application: UIApplicationProtocol!
    var spotifyAuthService: SpotifyAuthService!
    
    public convenience init(application: UIApplicationProtocol, spotifyAuthService: SpotifyAuthService) {
        self.init()
        self.init(title: nil, message: nil, preferredStyle: .ActionSheet)
        self.application = application
        self.spotifyAuthService = spotifyAuthService
        
        addActions()
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func addActions() {
        addAction(UIAlertAction(title: "Go to Spotify", style: .Default, handler: goToSpotify))
        if spotifyAuthService.hasSession {
            addAction(UIAlertAction(title: "Log out of Spotify", style: .Default, handler: logout))
        }
        addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
    }
    
    func goToSpotify(alertAction: UIAlertAction) {
        application.openURL(NSURL(string: "https://www.spotify.com")!)
    }
    
    func logout(alertAction: UIAlertAction) {
        spotifyAuthService.logout()
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
