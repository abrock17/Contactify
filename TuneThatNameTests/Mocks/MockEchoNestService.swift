import TuneThatName

class MockEchoNestService: EchoNestService {
    
    let mocker = Mocker()
    
    struct Method {
        static let findSongs = "findSongs"
    }
    
    override func findSongs(#titleSearchTerm: String, desiredNumberOfSongs: Int, callback: (EchoNestService.SongsResult) -> Void) {
        mocker.recordCall(Method.findSongs, parameters: titleSearchTerm, desiredNumberOfSongs)
        let mockedResult = mocker.returnValueForCallTo(Method.findSongs)
        if let mockedResult = mockedResult as? EchoNestService.SongsResult {
            callback(mockedResult)
        } else {
            callback(.Success([Song(title: "unimportant mocked song", artistName: nil, uri: NSURL(string: "unimportant:mocked-uri")!)]))
        }
    }
}

