import TuneThatName

class MockEchoNestService: EchoNestService {
    
    let mocker = Mocker()
    
    struct Method {
        static let findSong = "findSong"
    }
    
    override func findSong(#titleSearchTerm: String!, callback: (EchoNestService.SongResult) -> Void) {
        mocker.recordCall(Method.findSong, parameters: titleSearchTerm)
        let mockedResult = mocker.returnValueForCallTo(Method.findSong)
        if let mockedResult = mockedResult as? EchoNestService.SongResult {
            callback(mockedResult)
        } else {
            callback(.Success(Song(title: "unimportant mocked song", artistName: nil, uri: nil)))
        }
    }
}

