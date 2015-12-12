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
    @IBOutlet weak var helpText: UITextView!
    
    let paragraphs = [
        "Create music playlists using the names of the people stored in your phone contacts.",
        "• Getting Started:",
            "• Select the desired number of songs for your playlist.",
            "• Optionally select names you want to include in the playlist (or default to all names).",
            "• Choose some basic song preferences to set the mood.",
        "• Press Create Playlist, and Tune That Name will attempt to find songs with titles matching the names you provided.",
        "• Using a Spotify premium account, you can preview songs in your playlist, add additional songs, and remove or replace the songs you don't like.",
        "• NOTE - Playlists are currently not saved locally when Tune That Name is terminated.  If you want to keep a playlist, you can preserve it in your Spotify account by pressing Save to Spotify.",
        "Enjoy! Tune That Name is a fun way to discover new music and create playlists with a personal touch."
    ]
    let bold = ["Create Playlist", "Save to Spotify"]
    let italic = ["Tune That Name"]
    let fontSize: CGFloat = 14
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
        helpText.attributedText = attributedHelpText()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewDidAppear(animated)
        dispatch_async(dispatch_get_main_queue()) {
            self.helpText.setContentOffset(CGPointZero, animated: false)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        addGradient()
    }
    
    func addGradient() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.blackColor().CGColor, UIAppearanceManager.barBackground.CGColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = helpSubView.bounds
        helpSubView.layer.insertSublayer(gradientLayer, atIndex: 0)
        helpSubView.layer.borderWidth = 1
        helpSubView.layer.borderColor = UIColor.blackColor().CGColor
    }
    
    func attributedHelpText() -> NSAttributedString {
        let helpString = paragraphs.joinWithSeparator("\n")
        let attributes = [
            NSFontAttributeName: UIFont.systemFontOfSize(fontSize),
            NSForegroundColorAttributeName: UIAppearanceManager.barLabelText
        ]
        let attributedHelpText = NSMutableAttributedString(string: helpString, attributes: attributes)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 10
        
        applyAttribute(NSParagraphStyleAttributeName, of: paragraphStyle, forAllOccurencesOf: paragraphs.first!, inSource: attributedHelpText)
        
        indentForBullet(1,
            allOccurencesOf: [paragraphs[1], paragraphs[6],paragraphs[7]],
            inSource: attributedHelpText
        )
        indentForBullet(2,
            allOccurencesOf: [paragraphs[2], paragraphs[3], paragraphs[4], paragraphs[5]],
            inSource: attributedHelpText
        )
        
        italic.map({ applyAttribute(NSFontAttributeName, of: UIFont.italicSystemFontOfSize(fontSize), forAllOccurencesOf: $0, inSource: attributedHelpText) })
        bold.map({ applyAttribute(NSFontAttributeName, of: UIFont.boldSystemFontOfSize(fontSize), forAllOccurencesOf: $0, inSource: attributedHelpText) })
        
        return attributedHelpText
    }
    
    func indentForBullet(indentNumber: Int, allOccurencesOf searchStrings: [String], inSource source: NSMutableAttributedString) {
        let indentIncrement: CGFloat = 10.5
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.headIndent = CGFloat(indentNumber) * indentIncrement
        paragraphStyle.firstLineHeadIndent = paragraphStyle.headIndent - indentIncrement
        paragraphStyle.paragraphSpacing = 10.0
        
        for searchString in searchStrings {
            applyAttribute(NSParagraphStyleAttributeName, of: paragraphStyle, forAllOccurencesOf: searchString, inSource: source)
        }
    }
    
    func applyAttribute(key: String, of value: AnyObject, forAllOccurencesOf searchString: String,
        inSource source: NSMutableAttributedString) {
        let inputLength = source.string.characters.count
        let searchLength = searchString.characters.count
        var range = NSRange(location: 0, length: source.length)
        
        while (range.location != NSNotFound) {
            range = (source.string as NSString).rangeOfString(searchString, options: [], range: range)
            if (range.location != NSNotFound) {
                source.addAttribute(key, value: value, range: NSRange(location: range.location, length: searchLength))
                range = NSRange(location: range.location + range.length, length: inputLength - (range.location + range.length))
            }
        }
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
