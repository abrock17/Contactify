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
    var spotifyUserService: SpotifyUserService!
    
    public convenience init(presentingView: UIView, application: UIApplicationProtocol,
        spotifyAuthService: SpotifyAuthService, spotifyUserService: SpotifyUserService = SpotifyUserService()) {
        self.init()
        self.init(title: nil, message: nil, preferredStyle: .ActionSheet)
        self.application = application
        self.spotifyAuthService = spotifyAuthService
        self.spotifyUserService = spotifyUserService
        popoverPresentationController?.sourceView = presentingView
        popoverPresentationController?.sourceRect = presentingView.bounds
        
        if let currentUser = spotifyUserService.getCachedCurrentUser() {
            self.message = "Logged in as \"\(currentUser.username)\""
        }
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
        if spotifyAuthService.hasSession {
            addAction(UIAlertAction(title: "Log in as a different user", style: .Default, handler: reLogin))
        } else {
            addAction(UIAlertAction(title: "Log in to Spotify", style: .Default, handler: login))
        }
        addAction(UIAlertAction(title: "spotify.com", style: .Default, handler: goToSpotify))
        addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
    }
    
    func goToSpotify(alertAction: UIAlertAction) {
        application.openURL(NSURL(string: "https://www.spotify.com")!)
    }
    
    func login(alertAction: UIAlertAction) {
        // side-effect of calling this here - it will prompt the user to log in and cache the username upon success
        spotifyUserService.retrieveCurrentUser() {
            userResult in
            
            switch (userResult) {
            case .Success(let user):
                print("logged in as user: \(user)")
            case .Failure(let error):
                print("unable to retrieve current user after login: \(error)")
            }
        }
    }
    
    func reLogin(alertAction: UIAlertAction) {
        spotifyAuthService.logout()
        login(alertAction)
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
