import Foundation
import UIKit

class UIAppearanceManager {
    
    static let tint = UIAppearanceManager.rgbColor(66, 156, 223)
    static let mutedTint = UIAppearanceManager.rgbColor(155, 195, 225)
    static let barBackground = UIAppearanceManager.rgbColor(12, 28, 83)
    static let barLabelText = UIAppearanceManager.rgbColor(202, 202, 202)
    static let barTint = UIAppearanceManager.rgbColor(255, 255, 255)
    static let destructive = UIAppearanceManager.rgbColor(179, 45, 45)
    
    static func initializeAppearance() {

        let window = UIApplication.sharedApplication().delegate!.window!!
        window.tintColor = tint
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: .None)
        UIApplication.sharedApplication().statusBarStyle = .LightContent
        
        UISwitch.appearance().onTintColor = mutedTint
        
        initializeNavigationBarAppearance()
        initializeToolbarAppearance()
        
        UITableView.appearance().sectionIndexBackgroundColor = UIAppearanceManager.rgbColor(247, 247, 247)
    }
    
    static func initializeNavigationBarAppearance() {
        UINavigationBar.appearance().barTintColor = barBackground
        UINavigationBar.appearance().tintColor = barTint
        var navBarTitleTextAttributes = UINavigationBar.appearance().titleTextAttributes
        if navBarTitleTextAttributes == nil {
            navBarTitleTextAttributes = [String : AnyObject]()
        }
        navBarTitleTextAttributes![NSForegroundColorAttributeName] = barLabelText
        UINavigationBar.appearance().titleTextAttributes = navBarTitleTextAttributes
    }
    
    static func initializeToolbarAppearance() {
        UIToolbar.appearance().barTintColor = barBackground
        UIToolbar.appearance().backgroundColor = barBackground
        UIToolbar.appearance().tintColor = barTint
    }
    
    static func rgbColor(red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> UIColor {
        return UIColor(red: red/255.0, green: green/255.0, blue: blue/255.0, alpha: 1.0)
    }
}