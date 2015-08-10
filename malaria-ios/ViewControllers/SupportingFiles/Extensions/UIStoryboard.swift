import Foundation
import UIKit

extension UIStoryboard{
    ///Converts MyTarget.ClassName to ClassName
    private class func getSimpleClassName(c: AnyClass) -> String {
        return c.description().componentsSeparatedByString(".").last!
    }
    
    /// Instantiate a view controller from the storyboard main by default
    /// The storyboard Id must be equal to the name of the class. This is changed in the storyboard file.
    ///
    /// :param: `String optional`: named (default is Main)
    /// :param: `C`: Class of the view controller
    ///
    /// :returns: `C`: A new instance of the view controller
    public static func instantiate <C:UIViewController> (named: String = "Main", viewControllerClass: C.Type) -> C {
        let storyboard = UIStoryboard(name: named, bundle: nil)
        let storyboardId = UIStoryboard.getSimpleClassName(viewControllerClass)
        return storyboard.instantiateViewControllerWithIdentifier(storyboardId) as! C
    }
    
}