class MockUserDefaults: NSUserDefaults {
    
    struct Method {
        static let arrayForKey = "arrayForKey"
        static let dataForKey = "dataForKey"
        static let setObject = "setObject"
        static let boolForKey = "boolForKey"
        static let setBool = "setBool"
    }
    
    let mocker = Mocker()
    
    override func arrayForKey(defaultName: String) -> [AnyObject]? {
        mocker.recordCall(Method.arrayForKey, parameters: defaultName)
        return mocker.returnValueForCallTo(Method.arrayForKey) as? [NSData]
    }
    
    override func dataForKey(defaultName: String) -> NSData? {
        return mocker.mockCallTo(Method.dataForKey, parameters: defaultName) as? NSData
    }
    
    override func boolForKey(defaultName: String) -> Bool {
        mocker.recordCall(Method.boolForKey, parameters: defaultName)
        return mocker.returnValueForCallTo(Method.boolForKey) as! Bool
    }
    
    override func setObject(value: AnyObject?, forKey defaultName: String) {
        mocker.recordCall(Method.setObject, parameters: value, defaultName)
    }

    override func setBool(value: Bool, forKey defaultName: String) {
        mocker.recordCall(Method.setBool, parameters: value, defaultName)
    }
}