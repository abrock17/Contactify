import Foundation
import UIKit

public class UIAppearanceManager {
    
    static let tint = UIAppearanceManager.uiColorForRed(255, green: 255, blue: 124)
    static let barBackground = UIAppearanceManager.uiColorForRed(12, green: 28, blue: 83)
    static let barLabelText = UIAppearanceManager.uiColorForRed(202, green: 202, blue: 202)
    static let barTint = UIAppearanceManager.uiColorForRed(255, green: 255, blue: 255)
    
    public static func initializeAppearance() {
        UINavigationBar.appearance().barTintColor = barBackground
        UINavigationBar.appearance().tintColor = barTint
        var navBarTitleTextAttributes = UINavigationBar.appearance().titleTextAttributes
        if navBarTitleTextAttributes == nil {
            navBarTitleTextAttributes = [String : AnyObject]()
        }
        navBarTitleTextAttributes![NSForegroundColorAttributeName] = barLabelText
        UINavigationBar.appearance().titleTextAttributes = navBarTitleTextAttributes
        
        UIToolbar.appearance().barTintColor = barBackground
        UIToolbar.appearance().tintColor = barTint
    }
    
    static func uiColorForRed(red: CGFloat, green: CGFloat, blue: CGFloat) -> UIColor {
        return UIColor(red: red/255.0, green: green/255.0, blue: blue/255.0, alpha: 1.0)
    }
}