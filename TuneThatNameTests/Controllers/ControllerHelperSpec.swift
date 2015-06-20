import Foundation
import TuneThatName
import Quick
import Nimble

class ControllerHelperSpec: QuickSpec {
    
    override func spec() {
        describe("ControllerHelper") {
            let view = UIView()
            let activityIndicator = UIActivityIndicatorView()

            describe("handle begin background activity for view") {
                beforeEach() {
                    ControllerHelper.handleBeginBackgroundActivityForView(view, activityIndicator: activityIndicator)
                }
                
                it("disables user interaction on the view") {
                    expect(view.userInteractionEnabled).to(beFalse())
                }

                it("starts animating the activity indicator") {
                    expect(activityIndicator.isAnimating()).to(beTrue())
                }
            }
            
            describe("handle complete background activity for view") {
                beforeEach() {
                    view.userInteractionEnabled = false
                    activityIndicator.startAnimating()
                    ControllerHelper.handleCompleteBackgroundActivityForView(view, activityIndicator: activityIndicator)
                }
                
                it("enables user interaction on the view") {
                    expect(view.userInteractionEnabled).to(beTrue())
                }
                
                it("stops animating the activity indicator") {
                    expect(activityIndicator.isAnimating()).to(beFalse())
                }
            }
        }
    }
}
