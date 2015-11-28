import TuneThatName
import Foundation
import Quick
import Nimble

class ContactSpec: QuickSpec {
    
    let id1: Int32 = 1
    let id2: Int32 = 2
    let firstName1 = "billy"
    let firstName2 = "johnny"
    let lastName1 = "johnson"
    let lastName2 = "billson"
    let companyName = "Pizza Hut"

    override func spec() {
        
        describe("equality") {
            
            it("is when the ID and names match") {
                expect(
                    Contact(id: self.id1, firstName: self.firstName1, lastName: self.lastName1)).to(equal(
                    Contact(id: self.id1, firstName: self.firstName1, lastName: self.lastName1)))
            }
            
            it("is not when the IDs do not match") {
                expect(
                    Contact(id: self.id1, firstName: self.firstName1, lastName: self.lastName1)).toNot(equal(
                        Contact(id: self.id2, firstName: self.firstName1, lastName: self.lastName1)))
            }
            
            it("is not when the first names do not match") {
                expect(
                    Contact(id: self.id1, firstName: self.firstName1, lastName: self.lastName1)).toNot(equal(
                        Contact(id: self.id1, firstName: self.firstName2, lastName: self.lastName1)))
            }
            
            it("is not when the last names do not match") {
                expect(
                    Contact(id: self.id1, firstName: self.firstName1, lastName: self.lastName1)).toNot(equal(
                        Contact(id: self.id1, firstName: self.firstName1, lastName: self.lastName2)))
            }
        }
        
        describe("hash value") {
            it("is does not have a consistent hash value when all properties are not the same") {
                expect(Contact(id: self.id1, firstName: self.firstName1, lastName: self.lastName1).hashValue)
                    .toNot(equal(Contact(id: self.id2, firstName: self.firstName1, lastName: self.lastName1).hashValue))
            }

            it("is has a consistent hash value when ID, first and last names match") {
                expect(Contact(id: self.id1, firstName: self.firstName1, lastName: self.lastName1).hashValue)
                    .to(equal(Contact(id: self.id1, firstName: self.firstName1, lastName: self.lastName1).hashValue))
            }
        }
        
        describe("search string") {
            context("when the first name is not empty") {
                it("is the first name") {
                    expect(Contact(id: self.id1, firstName: self.firstName1, lastName: nil).searchString)
                        .to(equal(self.firstName1))
                }
            }
            
            context("when the first name is nil") {
                context("and the last name is not empty") {
                    it("is the last name") {
                        expect(Contact(id: self.id1, firstName: nil, lastName: self.lastName1).searchString)
                            .to(equal(self.lastName1))
                    }
                }
            }
            
            context("when the first name is empty") {
                context("and the last name is not empty") {
                    it("is the last name") {
                        expect(Contact(id: self.id1, firstName: "", lastName: self.lastName1).searchString)
                            .to(equal(self.lastName1))
                    }
                }
            }
            
            context("when the first name is blank") {
                context("and the last name is not empty") {
                    it("is the last name") {
                        expect(Contact(id: self.id1, firstName: "    ", lastName: self.lastName1).searchString)
                            .to(equal(self.lastName1))
                    }
                }
                
                context("and the last name is nil") {
                    context("and the full name is not empty") {
                        it("is the full name") {
                            expect(Contact(id: self.id1, firstName: "    ", lastName: nil, fullName: self.companyName).searchString)
                                .to(equal(self.companyName))
                        }
                    }
                }
                
                context("and the last name is blank") {
                    context("and the full name is not empty") {
                        it("is the full name") {
                            expect(Contact(id: self.id1, firstName: "    ", lastName: "\t\t", fullName: self.companyName).searchString)
                                .to(equal(self.companyName))
                        }
                    }
                    
                    context("and the full name is blank") {
                        it("is the empty string") {
                            expect(Contact(id: self.id1, firstName: "    ", lastName: " \r\n ", fullName: " ").searchString)
                                .to(equal(""))
                        }
                    }
                }
            }
        }
    }
}