import Foundation
import Quick
import Nimble

class TestSpec: QuickSpec {
    override func spec() {
        it("works") {
            expect(1 == 1).to(beTruthy())
        }
    }
}