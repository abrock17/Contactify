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
                mockAudioStreamingController = MockSPTAudioStreamingController(clientId: SpotifyService.clientID)
                spotifyAudioFacade = SpotifyAudioFacadeImpl(spotifyAudioController: mockAudioStreamingController, spotifyPlaybackDelegate: FakeSPTAudioStreamingPlaybackDelegate())
            }
            
            describe("play a playlist from a given index") {
                let session = SPTSession()
                let index = 1
                
                beforeEach() {
                }
                
                it("calls the audio streaming controller with the desired song URIs and index") {
                    spotifyAudioFacade.playPlaylist(self.playlist, fromIndex: index, inSession: session, callback: self.errorCallback)

                    expect(self.callbackErrors.isEmpty).toEventually(beFalse())
                    let playURIsParameters = mockAudioStreamingController.mocker.getNthCallTo(MockSPTAudioStreamingController.Method.playURIsFromIndex, n: 0)!
                    expect(playURIsParameters[0] as? [NSURL]).to(equal(self.playlist.songURIs))
                    expect(playURIsParameters[1] as? Int32).to(equal(Int32(index)))
                }
                
                it("calls back with no error") {
                    spotifyAudioFacade.playPlaylist(self.playlist, fromIndex: index, inSession: session, callback: self.errorCallback)
                    
                    expect(self.callbackErrors.isEmpty).to(beFalse())
                    expect(self.callbackErrors.first!).to(beNil())
                }
                
                context("when the audio streaming controller is not logged in") {
                    it("logs in with the provided session") {
                        spotifyAudioFacade.playPlaylist(self.playlist, fromIndex: index, inSession: session, callback: self.errorCallback)

                        expect(mockAudioStreamingController.mocker.getNthCallTo(MockSPTAudioStreamingController.Method.loginWithSession, n: 0)?.first as? SPTSession).to(equal(session))
                    }
                }
                
                context("when login calls back with an error") {
                    let error = NSError(domain: "spotify", code: 578, userInfo: [NSLocalizedDescriptionKey: "couldn't log in"])

                    it("calls back with the error") {
                        mockAudioStreamingController.mocker.prepareForCallTo(MockSPTAudioStreamingController.Method.loginWithSession, returnValue: error)
                        
                        spotifyAudioFacade.playPlaylist(self.playlist, fromIndex: index, inSession: session, callback: self.errorCallback)
                        
                        expect(self.callbackErrors.isEmpty).to(beFalse())
                        expect(self.callbackErrors.first!).to(equal(error))
                    }
                }
                
                context("when play URIs calls back with an error") {
                    let error = NSError(domain: "spotify", code: 689, userInfo: [NSLocalizedDescriptionKey: "couldn't play tracks"])

                    it("calls back with the error") {
                        mockAudioStreamingController.mocker.prepareForCallTo(MockSPTAudioStreamingController.Method.playURIsFromIndex, returnValue: error)
                        
                        spotifyAudioFacade.playPlaylist(self.playlist, fromIndex: index, inSession: session, callback: self.errorCallback)
                        
                        expect(self.callbackErrors.isEmpty).to(beFalse())
                        expect(self.callbackErrors.first!).to(equal(error))
                    }
                }
            }
            
            describe("toggle play") {
                it("calls back") {
                    spotifyAudioFacade.togglePlay(self.errorCallback)

                    expect(self.callbackErrors.isEmpty).to(beFalse())
                    expect(self.callbackErrors.first!).to(beNil())
                }
                
                context("when the audio streaming controller is not playing") {
                    it("sets isPlaying to true on the audio streaming controller") {
                        spotifyAudioFacade.togglePlay(self.errorCallback)
                        
                        expect(mockAudioStreamingController.mocker.getNthCallTo(MockSPTAudioStreamingController.Method.setIsPlaying, n: 0)?.first as? Bool).to(beTrue())
                    }
                }
                
                context("when setIsPlaying calls back with an error") {
                    let error = NSError(domain: "spotify", code: 790, userInfo: [NSLocalizedDescriptionKey: "couldn't set isPlaying"])
                    
                    it("calls back with the error") {
                        mockAudioStreamingController.mocker.prepareForCallTo(MockSPTAudioStreamingController.Method.setIsPlaying, returnValue: error)
                        
                        spotifyAudioFacade.togglePlay(self.errorCallback)
                        
                        expect(self.callbackErrors.isEmpty).to(beFalse())
                        expect(self.callbackErrors.first!).to(equal(error))
                    }
                }
            }
            
            describe("stop play") {
                it("calls back") {
                    spotifyAudioFacade.stopPlay(self.errorCallback)
                    
                    expect(self.callbackErrors.isEmpty).to(beFalse())
                    expect(self.callbackErrors.first!).to(beNil())
                }
                
                it("calls stop on the audio streaming controller") {
                    spotifyAudioFacade.stopPlay(self.errorCallback)
                    
                    expect(mockAudioStreamingController.mocker.recordedParameters[MockSPTAudioStreamingController.Method.stop]?.count).to(equal(1))
                }
                
                context("when stop calls back with an error") {
                    let error = NSError(domain: "spotify", code: 801, userInfo: [NSLocalizedDescriptionKey: "couldn't stop"])

                    it("calls back with the error") {
                        mockAudioStreamingController.mocker.prepareForCallTo(MockSPTAudioStreamingController.Method.stop, returnValue: error)
                        
                        spotifyAudioFacade.stopPlay(self.errorCallback)
                        
                        expect(self.callbackErrors.isEmpty).to(beFalse())
                        expect(self.callbackErrors.first!).to(equal(error))
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
        mocker.recordCall(Method.playURIsFromIndex, parameters: uris as! [NSURL], index)
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