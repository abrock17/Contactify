import TuneThatName
import Quick
import Nimble

class SpotifyAudioFacadeSpec: QuickSpec {
    
    let playlist = Playlist(name: "name", songsWithContacts:[
            (song: Song(title: "Hit the Road Jack", artistName: "Ray Charles", uri: NSURL(string: "spotify:track:1blficLzeYlqZ7WtIxulLq")!), contact: nil),
            (song: Song(title: "Diane Young", artistName: "Vampire Weekend", uri: NSURL(string: "spotify:track:27zVV7Q7LbqsjWm40HOXuq")!), contact: nil)
        ])
    let trackURIs = [NSURL(string: "spotify:track:1blficLzeYlqZ7WtIxulLq")!, NSURL(string: "spotify:track:27zVV7Q7LbqsjWm40HOXuq")!]
    
    var callbackErrors = [NSError?]()
    
    func errorCallback(error: NSError?) {
        callbackErrors.append(error)
    }
    
    override func spec() {
        describe("The Spotify Audio Facade") {
            var spotifyAudioFacade: SpotifyAudioFacade!
            var mockAudioStreamingController: MockSPTAudioStreamingController!
            var mockSpotifyAuthService: MockSpotifyAuthService!
            var mockSpotifyPlaybackDelegate: MockSpotifyPlaybackDelegate!
            
            beforeEach() {
                self.callbackErrors.removeAll(keepCapacity: false)
                mockSpotifyAuthService = MockSpotifyAuthService()
                mockAudioStreamingController = MockSPTAudioStreamingController(clientId: SpotifyService.clientID)
                spotifyAudioFacade = SpotifyAudioFacadeImpl(spotifyAudioController: mockAudioStreamingController, spotifyAuthService: mockSpotifyAuthService)
                mockSpotifyPlaybackDelegate = MockSpotifyPlaybackDelegate()
            }
            
            describe("set the playback delegate") {
                beforeEach() {
                    spotifyAudioFacade.playbackDelegate = mockSpotifyPlaybackDelegate
                }
                
                it("updates the playback status for the delegate") {
                    expect(
                        mockSpotifyPlaybackDelegate.mocker.getCallCountFor(MockSpotifyPlaybackDelegate.Method.changedPlaybackStatus))
                        .to(equal(1))
                }
                
                it("updates the current track for the delegate") {
                    expect(
                        mockSpotifyPlaybackDelegate.mocker.getCallCountFor(MockSpotifyPlaybackDelegate.Method.changedCurrentTrack))
                        .to(equal(1))
                }
            }
            
            describe("play tracks for uris from a given index") {
                let index = 1
                
                context("when the auth service calls back with an error") {
                    let error = NSError(domain: "com.spotify.ios", code: 9876, userInfo: [NSLocalizedDescriptionKey: "error logging in"])
                    
                    it("calls back with the error") {
                        mockSpotifyAuthService.mocker.prepareForCallTo(MockSpotifyAuthService.Method.doWithSession, returnValue: SpotifyAuthService.AuthResult.Failure(error))
                        
                        spotifyAudioFacade.playTracksForURIs(self.trackURIs, fromIndex: index, callback: self.errorCallback)
                        
                        expect(self.callbackErrors.isEmpty).toEventually(beFalse())
                        expect(self.callbackErrors[0]).toEventually(equal(error))
                    }
                }
                
                context("when the auth service calls back with canceled") {
                    it("calls back with no error") {
                        mockSpotifyAuthService.mocker.prepareForCallTo(MockSpotifyAuthService.Method.doWithSession, returnValue: SpotifyAuthService.AuthResult.Canceled)
                        
                        spotifyAudioFacade.playTracksForURIs(self.trackURIs, fromIndex: index, callback: self.errorCallback)
                        
                        expect(self.callbackErrors.isEmpty).to(beFalse())
                        if !self.callbackErrors.isEmpty {
                            expect(self.callbackErrors.first!).to(beNil())
                        }
                    }
                }
                
                context("when the auth service calls back with a session") {
                    let session = SPTSession()
                    
                    beforeEach() {
                        mockSpotifyAuthService.mocker.prepareForCallTo(MockSpotifyAuthService.Method.doWithSession, returnValue: SpotifyAuthService.AuthResult.Success(session))
                    }

                    it("calls the audio streaming controller with the track URIs, index") {
                        spotifyAudioFacade.playTracksForURIs(self.trackURIs, fromIndex: index, callback: self.errorCallback)
                        
                        expect(self.callbackErrors.isEmpty).toEventually(beFalse())
                        let playURIsParameters = mockAudioStreamingController.mocker.getNthCallTo(MockSPTAudioStreamingController.Method.playURIsFromIndex, n: 0)
                        expect(playURIsParameters?[0] as? [NSURL]).to(equal(self.trackURIs))
                        expect(playURIsParameters?[1] as? Int32).to(equal(Int32(index)))
                    }

                    context("and the audio streaming controller is not logged in") {
                        it("logs in with the provided session") {
                            spotifyAudioFacade.playTracksForURIs(self.trackURIs, fromIndex: index, callback: self.errorCallback)
                            
                            expect(mockAudioStreamingController.mocker.getNthCallTo(MockSPTAudioStreamingController.Method.loginWithSession, n: 0)?.first as? SPTSession).to(equal(session))
                        }
                    }

                    context("when audio streaming login calls back with an error") {
                        let error = NSError(domain: "spotify", code: 578, userInfo: [NSLocalizedDescriptionKey: "couldn't log in to stream yo' audio"])
                        
                        it("calls back with the error") {
                            mockAudioStreamingController.mocker.prepareForCallTo(MockSPTAudioStreamingController.Method.loginWithSession, returnValue: error)
                            
                            spotifyAudioFacade.playTracksForURIs(self.trackURIs, fromIndex: index, callback: self.errorCallback)
                            
                            expect(self.callbackErrors.isEmpty).to(beFalse())
                            expect(self.callbackErrors.first!).to(equal(error))
                        }
                    }

                    context("and play URIs calls back with an error") {
                        let error = NSError(domain: "spotify", code: 689, userInfo: [NSLocalizedDescriptionKey: "couldn't play tracks"])
                        
                        it("calls back with the error") {
                            mockAudioStreamingController.mocker.prepareForCallTo(MockSPTAudioStreamingController.Method.playURIsFromIndex, returnValue: error)
                            
                            spotifyAudioFacade.playTracksForURIs(self.trackURIs, fromIndex: index, callback: self.errorCallback)
                            
                            expect(self.callbackErrors.isEmpty).to(beFalse())
                            expect(self.callbackErrors.first!).to(equal(error))
                        }
                    }
                }
            }
            
            describe("play a playlist from a given index") {
                let session = SPTSession()
                let index = 1
                
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
            
            describe("update playlist") {
                let index = 1

                it("calls the audio streaming controller replacing the desired song URIs and index") {
                    spotifyAudioFacade.updatePlaylist(self.playlist, withIndex: index, callback: self.errorCallback)
                    
                    expect(self.callbackErrors.isEmpty).toEventually(beFalse())
                    let replaceURIsParameters = mockAudioStreamingController.mocker.getNthCallTo(MockSPTAudioStreamingController.Method.replaceURIsWithCurrentTrack, n: 0)!
                    expect(replaceURIsParameters[0] as? [NSURL]).to(equal(self.playlist.songURIs))
                    expect(replaceURIsParameters[1] as? Int32).to(equal(Int32(index)))
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
                    
                    expect(mockAudioStreamingController.mocker.getCallCountFor(
                        MockSPTAudioStreamingController.Method.stop)).to(equal(1))
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
            
            describe("audio streaming did change playback status") {
                beforeEach() {
                    spotifyAudioFacade.playbackDelegate = mockSpotifyPlaybackDelegate
                    mockSpotifyPlaybackDelegate.mocker.clearRecordedCallsTo(MockSpotifyPlaybackDelegate.Method.changedPlaybackStatus)
                    spotifyAudioFacade.audioStreaming?(mockAudioStreamingController, didChangePlaybackStatus: true)
                }
                
                it("captures the isPlaying value") {
                    expect(spotifyAudioFacade.isPlaying).to(beTrue())
                }
                
                it("passes the value to changedPlaybackStatus on the playback delegate") {
                    expect(mockSpotifyPlaybackDelegate.mocker.getNthCallTo(MockSpotifyPlaybackDelegate.Method.changedPlaybackStatus, n: 0)?.first as? Bool).to(equal(true))
                }
            }
            
            describe("audio streaming did change to track") {
                context("when track is nil") {
                    beforeEach() {
                        spotifyAudioFacade.playbackDelegate = mockSpotifyPlaybackDelegate
                        mockSpotifyPlaybackDelegate.mocker.clearRecordedCallsTo(MockSpotifyPlaybackDelegate.Method.changedCurrentTrack)
                        spotifyAudioFacade.audioStreaming?(mockAudioStreamingController, didChangeToTrack: nil)
                    }
                    
                    it("sets the current spotify track to nil") {
                        expect(spotifyAudioFacade.currentSpotifyTrack).to(beNil())
                    }
                    
                    it("passes the nil value to changedCurrentTrack on the playback delegate") {
                        expect(mockSpotifyPlaybackDelegate.mocker.getNthCallTo(MockSpotifyPlaybackDelegate.Method.changedCurrentTrack, n: 0)?.first as? SpotifyTrack).to(beNil())
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
        static let replaceURIsWithCurrentTrack = "replaceURIsWithCurrentTrack"
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
    
    override func replaceURIs(uris: [AnyObject]!, withCurrentTrack index: Int32, callback block: SPTErrorableOperationCallback!) {
        mocker.recordCall(Method.replaceURIsWithCurrentTrack, parameters: uris as! [NSURL], index)
        block(mocker.returnValueForCallTo(Method.replaceURIsWithCurrentTrack) as! NSError!)
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
