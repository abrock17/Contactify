import TuneThatName

class MockControllerHelper: ControllerHelper {
    
    let mocker = Mocker()
    
    struct Method {
        static let getImageForURL = "getImageForURL"
    }
    
    override func getImageForURL(url: NSURL, completionHandler: UIImage? -> Void) {
        mocker.recordCall(Method.getImageForURL, parameters: url)
        completionHandler(mocker.returnValueForCallTo(Method.getImageForURL) as? UIImage)
    }
}