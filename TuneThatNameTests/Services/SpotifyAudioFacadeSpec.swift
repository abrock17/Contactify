import TuneThatName
import Quick
import Nimble

class SpotifyAudioFacadeSpec: QuickSpec {
    
    let playlist = Playlist(name: "name", uri: nil, songs:
        [Song(title: "Hit the Road Jack", artistName: "Ray Charles", uri: NSURL(string: "spotify:track:1blficLzeYlqZ7WtIxulLq")!),
        Song(title: "Diane Young", artistName: "Vampire Weekend", uri: NSURL(string: "spotify:track:27zVV7Q7LbqsjWm40HOXuq")!)])
    
    var callbackErrors = [NSError?]()
    
    func errorCallback(error: NSError?) {
        callbackErrors.append(error)
    }
    
    override func spec() {
        describe("The Spotify Audio Facade") {
            var spotifyAudioFacade: SpotifyAudioFacade!
            var mockAudioStreamingController: MockSPTAudioStreamingController!
            
            beforeEach() {
                self.callbackErrors.removeAll(keepCapacity: false)
                mockAudioStreamingController = MockSPTAudioStreamingController(clientId: SpotifyService.clientID, audioController: nil)
                spotifyAudioFacade = SpotifyAudioFacadeImpl(spotifyAudioController: mockAudioStreamingController, spotifyPlaybackDelegate: FakeSPTAudioStreamingPlaybackDelegate())
            }
            
            describe("play a playlist from a given index") {
                context("when the audio streaming controller is not logged in") {
                    let session = SPTSession()
                    
                    it("logs in with the provided session") {
                        spotifyAudioFacade.playPlaylist(self.playlist, fromIndex: 1, inSession: session, callback: self.errorCallback)
                        
                        expect(self.callbackErrors.isEmpty).toEventually(beFalse())
                        expect(mockAudioStreamingController.mocker.getNthCallTo(MockSPTAudioStreamingController.Method.loginWithSession, n: 0)?.first as? SPTSession).to(equal(session))
                    }
                }
            }
        }
    }
}

class MockSPTAudioStreamingController: SPTAudioStreamingController {
    
    let mocker = Mocker()
    
    struct Method {
        static let loginWithSession = "loginWithSession"
        static let playURIsFromIndex = "playURIsFromIndex"
        static let setIsPlaying = "setIsPlaying"
        static let stop = "stop"
    }
    
    override func loginWithSession(session: SPTSession!, callback block: SPTErrorableOperationCallback!) {
        mocker.recordCall(Method.loginWithSession, parameters: session)
        block(mocker.returnValueForCallTo(Method.loginWithSession) as! NSError!)
    }
    
    override func playURIs(uris: [AnyObject]!, fromIndex index: Int32, callback block: SPTErrorableOperationCallback!) {
        mocker.recordCall(Method.playURIsFromIndex, parameters: uris, index)
        block(mocker.returnValueForCallTo(Method.playURIsFromIndex) as! NSError!)
    }
    
    override func setIsPlaying(playing: Bool, callback block: SPTErrorableOperationCallback!) {
        mocker.recordCall(Method.setIsPlaying, parameters: playing)
        block(mocker.returnValueForCallTo(Method.setIsPlaying) as! NSError!)
    }

    override func stop(block: SPTErrorableOperationCallback!) {
        mocker.recordCall(Method.stop)
        block(mocker.returnValueForCallTo(Method.stop) as! NSError!)
    }
}

class FakeSPTAudioStreamingPlaybackDelegate: NSObject, SPTAudioStreamingPlaybackDelegate {
}