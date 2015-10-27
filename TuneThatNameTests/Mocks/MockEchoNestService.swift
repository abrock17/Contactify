import TuneThatName

class MockEchoNestService: EchoNestService {
    
    let mocker = Mocker()
    
    struct Method {
        static let findSongs = "findSongs"
    }
    
    override func findSongs(titleSearchTerm titleSearchTerm: String, withSongPreferences songPreferences: SongPreferences,
        desiredNumberOfSongs: Int, inLocale locale: String? = nil, callback: (EchoNestService.SongsResult) -> Void) {
        mocker.recordCall(Method.findSongs, parameters: titleSearchTerm, songPreferences, desiredNumberOfSongs, locale)
        let mockedResult = mocker.returnValueForCallTo(Method.findSongs)
        if let mockedResult = mockedResult as? EchoNestService.SongsResult {
            callback(mockedResult)
        } else {
            callback(.Success([Song(title: "unimportant mocked song", artistName: nil, uri: NSURL(string: "unimportant:mocked-uri")!)]))
        }
    }
}

