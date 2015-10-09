import TuneThatName
import Quick
import Nimble

class SpotifySongSelectionTableControllerSpec: QuickSpec {
    
    var callbackSong: Song? = nil
    var callbackContact: Contact? = nil
    
    func songSelectionCompletionHandler(song: Song, contact: Contact?) {
        self.callbackSong = song
        self.callbackContact = contact
    }
    
    override func spec() {
        describe("SpotifySongSelectionTableController") {
            var spotifySongSelectionTableController: SpotifySongSelectionTableController!
            var navigationController: UINavigationController!
            var mockEchoNestService: MockEchoNestService!
            var mockPreferencesService: MockPreferencesService!
            let searchContact = Contact(id: 23, firstName: "Michael", lastName: "Jordan")
            let defaultPlaylistPreferences = PlaylistPreferences(numberOfSongs: 10, filterContacts: false, songPreferences:
                SongPreferences(characteristics: Set<SongPreferences.Characteristic>([.Positive])))
            let resultSongList = [
                Song(title: "Michael", artistName: "Franz Ferdinand", uri: NSURL(string: "spotify:track:1HcYhFRFQVSu8CGc0dl9to")!),
                Song(title: "The Ballad of Michael Valentine", artistName: "The Killers", uri:  NSURL(string: "spotify:track:2MwNreqilyOvET5lEiv9E1")!),
                Song(title: "Political Song for Michael Jackson to Sing", artistName: "Minutemen", uri: NSURL(string: "spotify:track:4dSug8anlR9XafooHaRbBR")!)
            ]
            
            beforeEach() {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                
                navigationController = storyboard.instantiateInitialViewController() as! UINavigationController
                
                spotifySongSelectionTableController = storyboard.instantiateViewControllerWithIdentifier("SpotifySongSelectionTableController") as!  SpotifySongSelectionTableController
                
                spotifySongSelectionTableController.searchContact = searchContact
                spotifySongSelectionTableController.songSelectionCompletionHandler = self.songSelectionCompletionHandler
                mockEchoNestService = MockEchoNestService()
                spotifySongSelectionTableController.echoNestService = mockEchoNestService
                mockPreferencesService = MockPreferencesService()
                spotifySongSelectionTableController.preferencesService = mockPreferencesService
            }
            
            describe("view load") {
                it("disables the done button") {
                    mockPreferencesService.mocker.prepareForCallTo(
                        MockPreferencesService.Method.retrievePlaylistPreferences, returnValue: defaultPlaylistPreferences)

                    self.loadViewForController(spotifySongSelectionTableController, withNavigationController: navigationController)

                    expect(spotifySongSelectionTableController.doneButton.enabled).toEventually(beFalse())
                }
                
                it("retrieves preferences from the preferences service") {
                    mockPreferencesService.mocker.prepareForCallTo(
                        MockPreferencesService.Method.retrievePlaylistPreferences, returnValue: defaultPlaylistPreferences)

                    self.loadViewForController(spotifySongSelectionTableController, withNavigationController: navigationController)
                    
                    expect(mockPreferencesService.mocker.getCallCountFor(MockPreferencesService.Method.retrievePlaylistPreferences)).toEventually(equal(1))
                }
                
                context("when there are no existing playlist preferences") {
                    it("gets the default playlist preferences from the preferences service") {
                        mockPreferencesService.mocker.prepareForCallTo(
                            MockPreferencesService.Method.retrievePlaylistPreferences, returnValue: nil)
                        mockPreferencesService.mocker.prepareForCallTo(
                            MockPreferencesService.Method.getDefaultPlaylistPreferences, returnValue: defaultPlaylistPreferences)
                        
                        self.loadViewForController(spotifySongSelectionTableController, withNavigationController: navigationController)
                        
                        expect(
                            mockPreferencesService.mocker.getCallCountFor(
                                MockPreferencesService.Method.getDefaultPlaylistPreferences)).toEventually(equal(1))
                    }
                }
                
                it("searches for songs from the echo nest service") {
                    mockPreferencesService.mocker.prepareForCallTo(
                        MockPreferencesService.Method.retrievePlaylistPreferences, returnValue: defaultPlaylistPreferences)

                    self.loadViewForController(spotifySongSelectionTableController, withNavigationController: navigationController)

                    expect(mockEchoNestService.mocker.getCallCountFor(MockEchoNestService.Method.findSongs))
                        .toEventually(equal(1))
                    expect(mockEchoNestService.mocker.getNthCallTo(
                        MockEchoNestService.Method.findSongs, n: 0)?[0] as? String)
                        .toEventually(equal(searchContact.firstName))
                    expect(mockEchoNestService.mocker.getNthCallTo(
                        MockEchoNestService.Method.findSongs, n: 0)?[1] as? SongPreferences)
                        .toEventually(equal(defaultPlaylistPreferences.songPreferences))
                    expect(mockEchoNestService.mocker.getNthCallTo(
                        MockEchoNestService.Method.findSongs, n: 0)?[2] as? Int)
                        .toEventually(equal(20))
                }
                
                context("when the song search returns an error") {
                    let error = NSError(domain: "domain", code: 0, userInfo: [NSLocalizedDescriptionKey: "ain't no songs for this name"])
                    it("displays the error message in an alert") {
                        mockPreferencesService.mocker.prepareForCallTo(
                            MockPreferencesService.Method.retrievePlaylistPreferences, returnValue: defaultPlaylistPreferences)
                        mockEchoNestService.mocker.prepareForCallTo(MockEchoNestService.Method.findSongs, returnValue: EchoNestService.SongsResult.Failure(error))
                        
                        self.loadViewForController(spotifySongSelectionTableController, withNavigationController: navigationController)
                        
                        self.assertSimpleUIAlertControllerPresentedOnController(spotifySongSelectionTableController, withTitle: "Error Searching for Songs", andMessage: error.localizedDescription)
                    }
                }

                context("when the song search returns a successful result") {
                    beforeEach() {
                        mockPreferencesService.mocker.prepareForCallTo(
                            MockPreferencesService.Method.retrievePlaylistPreferences, returnValue: defaultPlaylistPreferences)
                        mockEchoNestService.mocker.prepareForCallTo(MockEchoNestService.Method.findSongs, returnValue: EchoNestService.SongsResult.Success(resultSongList))
                        
                        self.loadViewForController(spotifySongSelectionTableController, withNavigationController: navigationController)
                    }
                    
                    it("displays the expected results in the table") {
                        expect(
                            spotifySongSelectionTableController.tableView(
                                spotifySongSelectionTableController.tableView, numberOfRowsInSection: 0))
                            .toEventually(equal(resultSongList.count))
                        for (index, song) in resultSongList.enumerate() {
                            expect(
                                spotifySongSelectionTableController.tableView(
                                    spotifySongSelectionTableController.tableView,
                                    cellForRowAtIndexPath: NSIndexPath(forRow: index, inSection: 0)).textLabel?.text)
                                .toEventually(equal(song.title))
                            expect(
                                spotifySongSelectionTableController.tableView(
                                    spotifySongSelectionTableController.tableView,
                                    cellForRowAtIndexPath: NSIndexPath(forRow: index, inSection: 0)).detailTextLabel?.text)
                                .toEventually(equal(song.displayArtistName))
                        }
                    }
                }
            }
            
            context("when the view loads successfully") {
                let indexPath = NSIndexPath(forRow: 1, inSection: 0)

                beforeEach() {
                    mockPreferencesService.mocker.prepareForCallTo(
                        MockPreferencesService.Method.retrievePlaylistPreferences, returnValue: defaultPlaylistPreferences)
                    mockEchoNestService.mocker.prepareForCallTo(MockEchoNestService.Method.findSongs, returnValue: EchoNestService.SongsResult.Success(resultSongList))
                    
                    self.loadViewForController(spotifySongSelectionTableController, withNavigationController: navigationController)
                    expect(spotifySongSelectionTableController.songs).toEventually(equal(resultSongList))
                }
                
                describe("did select a row") {
                    it("enables the done button") {
                        spotifySongSelectionTableController.tableView(spotifySongSelectionTableController.tableView, didSelectRowAtIndexPath: indexPath)
                        
                        expect(spotifySongSelectionTableController.doneButton.enabled).toEventually(beTrue())
                    }
                }
                
                describe("press the done button") {
                    it("calls the completion handler") {
                        spotifySongSelectionTableController.tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: .None)
                        
                        self.pressDoneButton(spotifySongSelectionTableController)
                        
                        expect(self.callbackSong).toEventually(equal(resultSongList[indexPath.row]))
                        expect(self.callbackContact).toEventually(equal(searchContact))
                    }
                }
            }
        }
    }
    
    func loadViewForController(viewController: UIViewController, withNavigationController navigationController: UINavigationController) {
        navigationController.pushViewController(viewController, animated: false)
        UIApplication.sharedApplication().keyWindow!.rootViewController = navigationController
    }
    
    func assertSimpleUIAlertControllerPresentedOnController(parentController: UIViewController, withTitle expectedTitle: String, andMessage expectedMessage: String) {
        expect(parentController.presentedViewController).toEventuallyNot(beNil())
        expect(parentController.presentedViewController).toEventually(beAnInstanceOf(UIAlertController))
        if let alertController = parentController.presentedViewController as? UIAlertController {
            expect(alertController.title).toEventually(equal(expectedTitle))
            expect(alertController.message).toEventually(equal(expectedMessage))
        }
    }
    
    func pressDoneButton(spotifySongSelectionTableController: SpotifySongSelectionTableController) {
        UIApplication.sharedApplication().sendAction(spotifySongSelectionTableController.doneButton.action,
        to: spotifySongSelectionTableController.doneButton.target, from: self, forEvent: nil)
    }
}