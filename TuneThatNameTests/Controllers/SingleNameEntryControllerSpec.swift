import TuneThatName
import Quick
import Nimble

class SingleNameEntryControllerSpec: QuickSpec {
    
    override func spec() {
        describe("SingleNameEntryController") {
            var singleNameEntryController: SingleNameEntryController!
            var navigationController: UINavigationController!
            var mockContactService: MockContactService!

            var contactList = [
                Contact(id: 1, firstName: "Johnny", lastName: "Bench", fullName: "Johnny Bench"),
                Contact(id: 2, firstName: "Billy", lastName: "Idol", fullName: "Billy Idol"),
                Contact(id: 3, firstName: "Frankie", lastName: "Avalon", fullName: "Frankie Avalon"),
                Contact(id: 4, firstName: "Prince", lastName: nil, fullName: "Prince"),
                Contact(id: 5, firstName: "", lastName: "Fletch", fullName: "Fletch")
            ]
            let songSelectionCompletionHandler = {
                (song: Song, contact: Contact?) -> () in
            }
            beforeEach() {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                
                navigationController = storyboard.instantiateInitialViewController() as! UINavigationController
                
                singleNameEntryController = storyboard.instantiateViewControllerWithIdentifier("SingleNameEntryController") as!  SingleNameEntryController
                
                singleNameEntryController.songSelectionCompletionHandler = songSelectionCompletionHandler
                mockContactService = MockContactService()
                singleNameEntryController.contactService = mockContactService
                mockContactService.mocker.prepareForCallTo(MockContactService.Method.retrieveAllContacts, returnValue: ContactService.ContactListResult.Success(contactList))

                navigationController.pushViewController(singleNameEntryController, animated: false)
                UIApplication.sharedApplication().keyWindow!.rootViewController = navigationController
                NSRunLoop.mainRunLoop().runUntilDate(NSDate())
            }
            
            describe("view did load") {
                it("retrieves all contacts from the contact service") {
                    expect(mockContactService.mocker.getCallCountFor(
                        MockContactService.Method.retrieveAllContacts)).toEventually(equal(1))
                }
                
                it("disables the done button") {
                    expect(singleNameEntryController.doneButton.enabled).to(beFalse())
                }
                
                it("hides the name suggestion table") {
                    expect(singleNameEntryController.nameSuggestionTableView.hidden).to(beTrue())
                }
            }
            
            describe("name entry text change") {
                context("when the text changes to empty") {
                    it("disables the done button") {
                        self.changeNameEntryTextTo("a", on: singleNameEntryController)
                        
                        self.changeNameEntryTextTo("", on: singleNameEntryController)
                        
                        expect(singleNameEntryController.doneButton.enabled).to(beFalse())
                    }
                }
                
                context("when the text changes to blank") {
                    it("disables the done button") {
                        self.changeNameEntryTextTo("a", on: singleNameEntryController)
                        
                        self.changeNameEntryTextTo("    ", on: singleNameEntryController)
                        
                        expect(singleNameEntryController.doneButton.enabled).to(beFalse())
                    }
                }
                
                context("when the text changes to non-empty") {
                    beforeEach() {
                        self.changeNameEntryTextTo("", on: singleNameEntryController)
                    }
                    context("and the text does not start with the same characters as a word in one of the suggested full names") {
                        let text = "c"
                        
                        beforeEach() {
                            self.changeNameEntryTextTo(text, on: singleNameEntryController)
                        }
                        
                        it("enables the done button") {
                            expect(singleNameEntryController.doneButton.enabled).to(beTrue())
                        }
                        
                        it("sets the first name on the contact") {
                            self.pressDoneButton(singleNameEntryController)
                            let spotifySongSelectionTableController = navigationController.topViewController as? SpotifySongSelectionTableController
                            expect(spotifySongSelectionTableController?.searchContact.firstName).to(equal(text))
                        }
                        
                        it("does not display the name suggestion table") {
                            expect(singleNameEntryController.nameSuggestionTableView.hidden).to(beTrue())
                        }
                    }
                    
                    context("and the text starts with the same characters as a word in one of the suggested full names") {
                        let text = "b"
                        let expectedSuggestedContacts = [contactList[1], contactList[0]]
                        
                        beforeEach() {
                            self.changeNameEntryTextTo(text, on: singleNameEntryController)
                        }
                        
                        it("enables the done button") {
                            expect(singleNameEntryController.doneButton.enabled).to(beTrue())
                        }
                        
                        it("displays the name suggestion table with the expectecd contacts") {
                            expect(singleNameEntryController.nameSuggestionTableView.hidden).to(beFalse())
                            expect(singleNameEntryController.tableView(singleNameEntryController.nameSuggestionTableView, numberOfRowsInSection: 0)).to(equal(2))
                            expect(singleNameEntryController.tableView(
                                singleNameEntryController.nameSuggestionTableView,
                                cellForRowAtIndexPath: NSIndexPath(forRow: 0, inSection: 0)).textLabel?.text)
                                .to(equal(expectedSuggestedContacts[0].fullName))
                            expect(singleNameEntryController.tableView(
                                singleNameEntryController.nameSuggestionTableView,
                                cellForRowAtIndexPath: NSIndexPath(forRow: 1, inSection: 0)).textLabel?.text)
                                .to(equal(expectedSuggestedContacts[1].fullName))
                        }
                    }
                }
            }
            
            describe("select a suggested name row") {
                context("when the selected contact has a first and last name") {
                    let text = "b"
                    let expectedContact = contactList[0]
                    
                    beforeEach() {
                        self.changeNameEntryTextTo(text, on: singleNameEntryController)
                        
                        singleNameEntryController.tableView(singleNameEntryController.nameSuggestionTableView, didSelectRowAtIndexPath: NSIndexPath(forRow: 1, inSection: 0))
                    }
                    
                    it("hides the name suggestion table") {
                        expect(singleNameEntryController.nameSuggestionTableView.hidden).to(beTrue())
                    }
                    
                    it("sets the name entry text field the expected value") {
                        expect(singleNameEntryController.nameEntryTextField.text)
                            .to(equal(expectedContact.firstName))
                    }
                    
                    it("sets the last name label to the expected value") {
                        expect(singleNameEntryController.lastNameLabel.text).to(equal("(\(expectedContact.lastName!))"))
                    }
                    
                    it("sets the selected contact") {
                        self.pressDoneButton(singleNameEntryController)
                        let spotifySongSelectionTableController = navigationController.topViewController as? SpotifySongSelectionTableController
                        expect(spotifySongSelectionTableController?.searchContact).to(equal(expectedContact))
                    }
                    
                    context("and the name entry text changes again") {
                        let newText = expectedContact.fullName + "warmer"
                        
                        beforeEach() {
                            self.changeNameEntryTextTo(newText, on: singleNameEntryController)
                        }
                        
                        it("clears the last name label") {
                            expect(singleNameEntryController.lastNameLabel.text).to(equal(""))
                        }
                        
                        it("resets the selected contact") {
                            self.pressDoneButton(singleNameEntryController)
                            let spotifySongSelectionTableController = navigationController.topViewController as? SpotifySongSelectionTableController
                            expect(spotifySongSelectionTableController?.searchContact.firstName).to(equal(newText))
                        }
                    }
                }
                
                context("when the selected contact has no last name") {
                    beforeEach() {
                        self.changeNameEntryTextTo("pri", on: singleNameEntryController)
                        
                        singleNameEntryController.tableView(singleNameEntryController.nameSuggestionTableView, didSelectRowAtIndexPath: NSIndexPath(forRow: 0, inSection: 0))
                    }
                    
                    it("clears the last name label") {
                        expect(singleNameEntryController.lastNameLabel.text).to(equal(""))
                    }
                    
                    it("sets the selected contact") {
                        self.pressDoneButton(singleNameEntryController)
                        let spotifySongSelectionTableController = navigationController.topViewController as? SpotifySongSelectionTableController
                        expect(spotifySongSelectionTableController?.searchContact).to(equal(contactList[3]))
                    }
                }

                context("when the selected contact has no first name") {
                    beforeEach() {
                        self.changeNameEntryTextTo("fle", on: singleNameEntryController)
                        
                        singleNameEntryController.tableView(singleNameEntryController.nameSuggestionTableView, didSelectRowAtIndexPath: NSIndexPath(forRow: 0, inSection: 0))
                    }
                    
                    it("sets the name entry text field to the last name") {
                        expect(singleNameEntryController.nameEntryTextField.text)
                            .to(equal(contactList[4].lastName))
                    }
                    
                    it("clears the last name label") {
                        expect(singleNameEntryController.lastNameLabel.text).to(equal(""))
                    }
                    
                    it("sets the selected contact") {
                        self.pressDoneButton(singleNameEntryController)
                        let spotifySongSelectionTableController = navigationController.topViewController as? SpotifySongSelectionTableController
                        expect(spotifySongSelectionTableController?.searchContact).to(equal(contactList[4]))
                    }
                }
            }
            
            describe("press done button") {
                let firstName = "Shaniqua"
                beforeEach() {
                    self.changeNameEntryTextTo(firstName, on: singleNameEntryController)
                    
                    self.pressDoneButton(singleNameEntryController)
                }
                
                it("segues to the song selection controller") {
                    expect(navigationController.topViewController)
                        .toEventually(beAnInstanceOf(SpotifySongSelectionTableController))
                }
                
                it("sets the searchContact on the song selection controller") {
                    let spotifySongSelectionTableController = navigationController.topViewController as? SpotifySongSelectionTableController
                    expect(spotifySongSelectionTableController?.searchContact.firstName).to(equal(firstName))
                }
                
                it("passes the song selection completion handler to the song selection controller") {
                    let spotifySongSelectionTableController = navigationController.topViewController as? SpotifySongSelectionTableController
                    expect(spotifySongSelectionTableController?.songSelectionCompletionHandler).toNot(beNil())
                }
            }
        }
    }
    
    func changeNameEntryTextTo(text: String, on singleNameEntryController: SingleNameEntryController) {
        singleNameEntryController.nameEntryTextField.text = text
        singleNameEntryController.nameEntryTextChanged(singleNameEntryController.nameEntryTextField)
    }
    
    
    func pressDoneButton(singleNameEntryController: SingleNameEntryController) {
        UIApplication.sharedApplication().sendAction(singleNameEntryController.doneButton.action,
            to: singleNameEntryController.doneButton.target, from: self, forEvent: nil)
    }
}
