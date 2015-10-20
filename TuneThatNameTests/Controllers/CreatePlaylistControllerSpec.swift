import TuneThatName
import Quick
import Nimble
import UIKit

class CreatePlaylistControllerSpec: QuickSpec {
    
    override func spec() {
        describe("CreatePlaylistController") {
            var navigationController: UINavigationController!
            var createPlaylistController: CreatePlaylistController!
            var mockPlaylistService: MockPlaylistService!
            var mockPreferencesService: MockPreferencesService!
            let defaultPlaylistPreferences = PlaylistPreferences(numberOfSongs: 10, filterContacts: false, songPreferences: SongPreferences(characteristics: Set<SongPreferences.Characteristic>([.Popular])))
            let numberOfSongsSliderInitialValue = 0.1837
            
            beforeEach() {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                navigationController = storyboard.instantiateInitialViewController() as! UINavigationController

                createPlaylistController = storyboard.instantiateViewControllerWithIdentifier("CreatePlaylistController") as! CreatePlaylistController
                
                mockPlaylistService = MockPlaylistService()
                createPlaylistController.playlistService = mockPlaylistService
                mockPreferencesService = MockPreferencesService()
                createPlaylistController.preferencesService = mockPreferencesService
                
                mockPreferencesService.mocker.prepareForCallTo(MockPreferencesService.Method.retrievePlaylistPreferences, returnValue: nil)
                mockPreferencesService.mocker.prepareForCallTo(MockPreferencesService.Method.getDefaultPlaylistPreferences, returnValue: defaultPlaylistPreferences)

                navigationController.pushViewController(createPlaylistController, animated: false)
                UIApplication.sharedApplication().keyWindow!.rootViewController = navigationController
                NSRunLoop.mainRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 0.1))
            }
            
            it("loads playlist preferences from preferences service") {
                expect(
                    mockPreferencesService.mocker.getCallCountFor(
                        MockPreferencesService.Method.retrievePlaylistPreferences)).toEventually(equal(1))
            }
            
            context("when there are no existing playlist preferences") {
                it("gets the default playlist preferences from the preferences service") {
                    expect(
                        mockPreferencesService.mocker.getCallCountFor(
                            MockPreferencesService.Method.getDefaultPlaylistPreferences)).toEventually(equal(1))
                }
            }
            
            describe("number of songs slider") {
                it("has the correct initial value") {
                    expect(createPlaylistController.numberOfSongsSlider.value).to(beCloseTo(numberOfSongsSliderInitialValue, within: 0.0001))
                }
            }
            
            describe("number of songs label") {
                it("has the correct initial text") {
                    expect(createPlaylistController.numberOfSongsLabel.text).to(
                        equal(String(defaultPlaylistPreferences.numberOfSongs)))
                }
            }
            
            describe("favor popular songs switch") {
                it("has the correct initial state") {
                    expect(createPlaylistController.favorPopularSwitch.on).to(beTrue())
                }
            }
            
            describe("favor positive songs switch") {
                it("has the correct initial state") {
                    expect(createPlaylistController.favorPositiveSwitch.on).to(beFalse())
                }
            }
            
            describe("favor negative songs switch") {
                it("has the correct initial state") {
                    expect(createPlaylistController.favorNegativeSwitch.on).to(beFalse())
                }
            }
            
            describe("favor energetic songs switch") {
                it("has the correct initial state") {
                    expect(createPlaylistController.favorEnergeticSwitch.on).to(beFalse())
                }
            }
            
            describe("favor chill songs switch") {
                it("has the correct initial state") {
                    expect(createPlaylistController.favorChillSwitch.on).to(beFalse())
                }
            }
            
            describe("select names button") {
                it("has the correct initial state") {
                    expect(createPlaylistController.selectNamesButton.titleLabel?.text).to(equal("Select Names"))
                    expect(createPlaylistController.selectNamesButton.enabled).to(beFalse())
                }
            }
            
            describe("filter contacts switch") {
                it("has the correct initial state") {
                    expect(createPlaylistController.filterContactsSwitch.on).to(
                        equal(defaultPlaylistPreferences.filterContacts))
                }
            }
            
            describe("number of songs slider value change") {
                context("when value changes") {
                    it("updates the number of songs label accordingly") {
                        createPlaylistController.numberOfSongsSlider.value = 1
                        createPlaylistController.numberOfSongsValueChanged(createPlaylistController.numberOfSongsSlider)
                        
                        expect(createPlaylistController.numberOfSongsLabel.text).to(equal("50"))
                    }
                }
            }
            
            describe("increment number of songs pressed") {
                beforeEach() {
                    createPlaylistController.numberOfSongsSlider.value = Float(numberOfSongsSliderInitialValue)
                    createPlaylistController.numberOfSongsValueChanged(createPlaylistController.numberOfSongsSlider)

                    createPlaylistController.incrementNumberOfSongsButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
                }
                
                it("updates the number of songs label accordingly") {
                    expect(createPlaylistController.numberOfSongsLabel.text).to(equal("11"))
                }
                
                it("updates the number of songs slider accordingly") {
                    expect(createPlaylistController.numberOfSongsSlider.value).to(beCloseTo(0.2041, within: 0.0001))
                }
            }
            
            describe("decrement number of songs pressed") {
                beforeEach() {
                    createPlaylistController.numberOfSongsSlider.value = Float(numberOfSongsSliderInitialValue)
                    createPlaylistController.numberOfSongsValueChanged(createPlaylistController.numberOfSongsSlider)
                    
                    createPlaylistController.decrementNumberOfSongsButton
                        .sendActionsForControlEvents(UIControlEvents.TouchUpInside)
                }
                
                it("updates the number of songs label accordingly") {
                    expect(createPlaylistController.numberOfSongsLabel.text).to(equal("9"))
                }
                
                it("updates the number of songs slider accordingly") {
                    expect(createPlaylistController.numberOfSongsSlider.value).to(beCloseTo(0.1633, within: 0.0001))
                }
            }
            
            describe("favor popular songs switch state change") {
                beforeEach() {
                    createPlaylistController.favorPopularSwitch.on = false
                    createPlaylistController.favorPopularStateChanged(createPlaylistController.favorPopularSwitch)
                }
                
                context("when state changes to false") {
                    it("removes popular characteristic from song preferences") {
                        self.assertUponPlaylistCreationInController(createPlaylistController,
                            withMockPlaylistService: mockPlaylistService,
                            songPreferencesDoNotContainCharacteristic: SongPreferences.Characteristic.Popular)
                    }
                }

                context("when state changes to true") {
                    it("adds popular characteristic to song preferences") {
                        createPlaylistController.favorPopularSwitch.on = true
                        createPlaylistController.favorPopularStateChanged(createPlaylistController.favorPopularSwitch)
                        
                        self.assertUponPlaylistCreationInController(createPlaylistController,
                            withMockPlaylistService: mockPlaylistService,
                            songPreferencesContainsCharacteristic: SongPreferences.Characteristic.Popular)
                    }
                }
            }
            
            describe("favor positive songs switch state change") {
                context("when state changes to true") {
                    it("adds positive characteristic to song preferences") {
                        createPlaylistController.favorPositiveSwitch.on = true
                        createPlaylistController.favorPositiveStateChanged(createPlaylistController.favorPositiveSwitch)

                        self.assertUponPlaylistCreationInController(createPlaylistController,
                            withMockPlaylistService: mockPlaylistService,
                            songPreferencesContainsCharacteristic: SongPreferences.Characteristic.Positive)
                    }
                }
                
                context("when state changes to false") {
                    it("removes positive characteristic from song preferences") {
                        createPlaylistController.favorPositiveSwitch.on = true
                        createPlaylistController.favorPositiveStateChanged(createPlaylistController.favorPositiveSwitch)
                        
                        createPlaylistController.favorPositiveSwitch.on = false
                        createPlaylistController.favorPositiveStateChanged(createPlaylistController.favorPositiveSwitch)
                        
                        self.assertUponPlaylistCreationInController(createPlaylistController,
                            withMockPlaylistService: mockPlaylistService,
                            songPreferencesDoNotContainCharacteristic: SongPreferences.Characteristic.Positive)
                    }
                }
                
                context("when negative characteristic is in song preferences") {
                    beforeEach() {
                        createPlaylistController.favorNegativeSwitch.on = true
                        createPlaylistController.favorNegativeStateChanged(createPlaylistController.favorNegativeSwitch)
                    }
                    
                    context("and state changes to true") {
                        beforeEach() {
                            createPlaylistController.favorPositiveSwitch.on = true
                            createPlaylistController.favorPositiveStateChanged(createPlaylistController.favorPositiveSwitch)
                        }
                        
                        it("sets the favor negative switch state to false") {
                            expect(createPlaylistController.favorNegativeSwitch.on).toEventually(beFalse())
                        }
                        
                        it("removes negative characteristic from song preferences") {
                            self.assertUponPlaylistCreationInController(createPlaylistController,
                                withMockPlaylistService: mockPlaylistService,
                                songPreferencesDoNotContainCharacteristic: SongPreferences.Characteristic.Negative)
                        }
                    }
                }
            }
            
            describe("favor negative songs switch state change") {
                context("when state changes to true") {
                    it("adds negative characteristic to song preferences") {
                        createPlaylistController.favorNegativeSwitch.on = true
                        createPlaylistController.favorNegativeStateChanged(createPlaylistController.favorNegativeSwitch)

                        self.assertUponPlaylistCreationInController(createPlaylistController,
                            withMockPlaylistService: mockPlaylistService,
                            songPreferencesContainsCharacteristic: SongPreferences.Characteristic.Negative)
                    }
                }
                
                context("when state changes to false") {
                    it("removes negative characteristic from song preferences") {
                        createPlaylistController.favorNegativeSwitch.on = true
                        createPlaylistController.favorNegativeStateChanged(createPlaylistController.favorNegativeSwitch)

                        createPlaylistController.favorNegativeSwitch.on = false
                        createPlaylistController.favorNegativeStateChanged(createPlaylistController.favorNegativeSwitch)
                        
                        self.assertUponPlaylistCreationInController(createPlaylistController,
                            withMockPlaylistService: mockPlaylistService,
                            songPreferencesDoNotContainCharacteristic: SongPreferences.Characteristic.Negative)
                    }
                }

                context("when positive characteristic is in song preferences") {
                    beforeEach() {
                        createPlaylistController.favorPositiveSwitch.on = true
                        createPlaylistController.favorPositiveStateChanged(createPlaylistController.favorPositiveSwitch)
                    }
                    
                    context("and state changes to true") {
                        beforeEach() {
                            createPlaylistController.favorNegativeSwitch.on = true
                            createPlaylistController.favorNegativeStateChanged(createPlaylistController.favorNegativeSwitch)
                        }
                        
                        it("sets the favor positive switch state to false") {
                            expect(createPlaylistController.favorPositiveSwitch.on).toEventually(beFalse())
                        }
                        
                        it("removes positive characteristic from song preferences") {
                            self.assertUponPlaylistCreationInController(createPlaylistController,
                                withMockPlaylistService: mockPlaylistService,
                                songPreferencesDoNotContainCharacteristic: SongPreferences.Characteristic.Positive)
                        }
                    }
                }
            }
            
            describe("favor energetic songs switch state change") {
                beforeEach() {
                    createPlaylistController.favorEnergeticSwitch.on = true
                    createPlaylistController.favorEnergeticStateChanged(createPlaylistController.favorEnergeticSwitch)
                }
                
                context("when state changes to true") {
                    it("adds energetic characteristic to song preferences") {
                        self.assertUponPlaylistCreationInController(createPlaylistController,
                            withMockPlaylistService: mockPlaylistService,
                            songPreferencesContainsCharacteristic: SongPreferences.Characteristic.Energetic)
                    }
                }
                
                context("when state changes to false") {
                    it("removes energetic characteristic from song preferences") {
                        createPlaylistController.favorEnergeticSwitch.on = false
                        createPlaylistController.favorEnergeticStateChanged(createPlaylistController.favorEnergeticSwitch)
                        
                        self.assertUponPlaylistCreationInController(createPlaylistController,
                            withMockPlaylistService: mockPlaylistService,
                            songPreferencesDoNotContainCharacteristic: SongPreferences.Characteristic.Energetic)
                    }
                }
                
                context("when chill characteristic is in song preferences") {
                    beforeEach() {
                        createPlaylistController.favorChillSwitch.on = true
                        createPlaylistController.favorChillStateChanged(createPlaylistController.favorChillSwitch)
                    }
                    
                    context("and state changes to true") {
                        beforeEach() {
                            createPlaylistController.favorEnergeticSwitch.on = true
                            createPlaylistController.favorEnergeticStateChanged(createPlaylistController.favorEnergeticSwitch)
                        }
                        
                        it("sets the favor chill switch state to false") {
                            expect(createPlaylistController.favorChillSwitch.on).toEventually(beFalse())
                        }
                        
                        it("removes chill characteristic from song preferences") {
                            self.assertUponPlaylistCreationInController(createPlaylistController,
                                withMockPlaylistService: mockPlaylistService,
                                songPreferencesDoNotContainCharacteristic: SongPreferences.Characteristic.Chill)
                        }
                    }
                }
            }
            
            describe("favor chill songs switch state change") {
                beforeEach() {
                    createPlaylistController.favorChillSwitch.on = true
                    createPlaylistController.favorChillStateChanged(createPlaylistController.favorChillSwitch)
                }
                
                context("when state changes to true") {
                    it("adds chill characteristic to song preferences") {
                        self.assertUponPlaylistCreationInController(createPlaylistController,
                            withMockPlaylistService: mockPlaylistService,
                            songPreferencesContainsCharacteristic: SongPreferences.Characteristic.Chill)
                    }
                }
                
                context("when state changes to false") {
                    it("removes chill characteristic from song preferences") {
                        createPlaylistController.favorChillSwitch.on = false
                        createPlaylistController.favorChillStateChanged(createPlaylistController.favorChillSwitch)
                        
                        self.assertUponPlaylistCreationInController(createPlaylistController,
                            withMockPlaylistService: mockPlaylistService,
                            songPreferencesDoNotContainCharacteristic: SongPreferences.Characteristic.Chill)
                    }
                }
                
                context("when energetic characteristic is in song preferences") {
                    beforeEach() {
                        createPlaylistController.favorEnergeticSwitch.on = true
                        createPlaylistController.favorEnergeticStateChanged(createPlaylistController.favorEnergeticSwitch)
                    }
                    
                    context("and state changes to true") {
                        beforeEach() {
                            createPlaylistController.favorChillSwitch.on = true
                            createPlaylistController.favorChillStateChanged(createPlaylistController.favorChillSwitch)
                        }
                        
                        it("sets the favor energetic switch state to false") {
                            expect(createPlaylistController.favorEnergeticSwitch.on).toEventually(beFalse())
                        }
                        
                        it("removes energetic characteristic from song preferences") {
                            self.assertUponPlaylistCreationInController(createPlaylistController,
                                withMockPlaylistService: mockPlaylistService,
                                songPreferencesDoNotContainCharacteristic: SongPreferences.Characteristic.Energetic)
                        }
                    }
                }
            }
            
            describe("filter contacts state change") {
                context("to true") {
                    
                    beforeEach() {
                        createPlaylistController.filterContactsSwitch.on = true
                        createPlaylistController.filterContactsStateChanged(createPlaylistController.filterContactsSwitch)
                    }
                    
                    it("updates the 'select names' button appropriately") {
                        expect(createPlaylistController.selectNamesButton.enabled).toEventually(beTrue())
                    }
                    
                    it("updates the filter contacts flag") {
                        createPlaylistController.createPlaylistButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
                        expect((mockPlaylistService.mocker.getNthCallTo(MockPlaylistService.Method.createPlaylistWithPreferences, n: 0)?.first as? PlaylistPreferences)?.filterContacts).toEventually(beTrue())
                    }
                    
                    it("segues to the name selection view") {
                        expect(navigationController.topViewController)
                            .toEventually(beAnInstanceOf(NameSelectionTableController))
                    }
                }
                
                context("to false") {
                    beforeEach() {
                        createPlaylistController.filterContactsSwitch.on = false
                        createPlaylistController.filterContactsStateChanged(createPlaylistController.filterContactsSwitch)
                    }
                    
                    it("updates the 'select names' button appropriately") {
                        expect(createPlaylistController.selectNamesButton.enabled).toEventually(beFalse())
                    }
                    
                    it("updates the filter contacts flag") {
                        createPlaylistController.createPlaylistButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
                        expect((mockPlaylistService.mocker.getNthCallTo(MockPlaylistService.Method.createPlaylistWithPreferences, n: 0)?.first as? PlaylistPreferences)?.filterContacts).toEventually(beFalse())
                    }

                    it("does not segue") {
                        expect(navigationController.topViewController).toEventually(beAnInstanceOf(CreatePlaylistController))
                    }
                }
            }
            
            describe("press the 'select names' button") {
                beforeEach() {
                    createPlaylistController.selectNamesButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
                }

                it("segues to the name selection view") {
                    expect(navigationController.topViewController).toEventually(beAnInstanceOf(NameSelectionTableController))
                }
                
                it("saves playlist preferences") {
                    expect(mockPreferencesService.mocker.getNthCallTo(
                        MockPreferencesService.Method.savePlaylistPreferences, n: 0)?.first as? PlaylistPreferences).toEventually(equal(defaultPlaylistPreferences))
                }
            }

            describe("press the create playlist button") {
                it("calls the playlist service with the correct number of songs") {
                    createPlaylistController.createPlaylistButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)

                    expect((mockPlaylistService.mocker.getNthCallTo(MockPlaylistService.Method.createPlaylistWithPreferences, n: 0)?.first as? PlaylistPreferences)?.numberOfSongs).toEventually(equal(defaultPlaylistPreferences.numberOfSongs))
                }
                
                context("when the playlist service calls back with an error") {
                    let expectedError = NSError(domain: "domain", code: 435, userInfo: [NSLocalizedDescriptionKey: "an error description"])
                    beforeEach() {
                        mockPlaylistService.mocker.prepareForCallTo(MockPlaylistService.Method.createPlaylistWithPreferences, returnValue: PlaylistService.PlaylistResult.Failure(expectedError))
                        
                        createPlaylistController.createPlaylistButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
                    }
                    
                    it("does not segue to the playlist table view") {
                        expect(navigationController.topViewController).toEventuallyNot(beAnInstanceOf(SpotifyPlaylistTableController))
                    }

                    it("displays the error message in an alert") {
                        expect(createPlaylistController.presentedViewController).toEventuallyNot(beNil())
                        expect(createPlaylistController.presentedViewController).toEventually(beAnInstanceOf(UIAlertController))
                        let alertController = createPlaylistController.presentedViewController as! UIAlertController
                        expect(alertController.title).toEventually(equal("Unable to Create Your Playlist"))
                        expect(alertController.message).toEventually(equal((expectedError.userInfo[NSLocalizedDescriptionKey] as! String)))
                    }
                }
                
                context("when the playlist service calls back with a playlist") {
                    let expectedPlaylist = Playlist(name: "playlist")
                    beforeEach() {
                        mockPlaylistService.mocker.prepareForCallTo(MockPlaylistService.Method.createPlaylistWithPreferences, returnValue: PlaylistService.PlaylistResult.Success(expectedPlaylist))
                        
                        createPlaylistController.createPlaylistButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
                        NSRunLoop.mainRunLoop().runUntilDate(NSDate())
                    }
                    
                    it("segues to the playlist table view passing the playlist") {
                        expect(navigationController.topViewController).toEventually(
                            beAnInstanceOf(SpotifyPlaylistTableController))
                        let spotifyPlaylistTableController = navigationController.topViewController as? SpotifyPlaylistTableController
                        expect(spotifyPlaylistTableController?.playlist).to(equal(expectedPlaylist))
                    }
                    
                    it("saves playlist preferences") {
                        expect(mockPreferencesService.mocker.getNthCallTo(
                            MockPreferencesService.Method.savePlaylistPreferences, n: 0)?.first as? PlaylistPreferences).toEventually(equal(defaultPlaylistPreferences))
                    }
                }
            }
        }
    }
    
    func assertUponPlaylistCreationInController(createPlaylistController: CreatePlaylistController,
        withMockPlaylistService mockPlaylistService: MockPlaylistService,
        songPreferencesContainsCharacteristic characteristic: SongPreferences.Characteristic) {
            createPlaylistController.createPlaylistButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
            expect(
                (mockPlaylistService.mocker.getNthCallTo(MockPlaylistService.Method.createPlaylistWithPreferences, n: 0)?.first as? PlaylistPreferences)?.songPreferences.characteristics)
                .toEventually(contain(characteristic))
    }
    
    func assertUponPlaylistCreationInController(createPlaylistController: CreatePlaylistController,
        withMockPlaylistService mockPlaylistService: MockPlaylistService,
        songPreferencesDoNotContainCharacteristic characteristic: SongPreferences.Characteristic) {
            createPlaylistController.createPlaylistButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
            NSRunLoop.mainRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 0.25))
            expect(
                (mockPlaylistService.mocker.getNthCallTo(MockPlaylistService.Method.createPlaylistWithPreferences, n: 0)?.first as? PlaylistPreferences)?.songPreferences.characteristics)
                .toEventuallyNot(contain(characteristic))
    }
}

class MockPlaylistService: PlaylistService {
    
    let mocker = Mocker()
    
    struct Method {
        static let createPlaylistWithPreferences = "createPlaylistWithPreferences"
    }
    
    override func createPlaylistWithPreferences(playlistPreferences: PlaylistPreferences, callback: PlaylistService.PlaylistResult -> Void) {
        mocker.recordCall(Method.createPlaylistWithPreferences, parameters: playlistPreferences)
        let mockedResult = mocker.returnValueForCallTo(Method.createPlaylistWithPreferences)
        if let mockedResult = mockedResult as? PlaylistService.PlaylistResult {
            callback(mockedResult)
        } else {
            callback(.Success(Playlist(name: "unimportant mocked playlist")))
        }
    }
}