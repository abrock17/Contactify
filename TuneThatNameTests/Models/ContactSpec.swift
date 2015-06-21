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

    override func spec() {
        
        describe("equality") {
            
            it("is when the names match") {
                expect(
                    Contact(id: self.id1, firstName: self.firstName1, lastName: self.lastName1)).to(equal(
                    Contact(id: self.id2, firstName: self.firstName1, lastName: self.lastName1)))
            }
            
            it("is when the IDs match") {
                expect(
                    Contact(id: self.id1, firstName: self.firstName1, lastName: self.lastName1)).to(equal(
                        Contact(id: self.id1, firstName: self.firstName2, lastName: self.lastName1)))
            }
            
            it("is not when the ID and first names do not match") {
                expect(
                    Contact(id: self.id1, firstName: self.firstName1, lastName: self.lastName1)).toNot(equal(
                        Contact(id: self.id2, firstName: self.firstName2, lastName: self.lastName1)))
            }
            
            it("is not when the ID and last names do not match") {
                expect(
                    Contact(id: self.id1, firstName: self.firstName1, lastName: self.lastName1)).toNot(equal(
                        Contact(id: self.id2, firstName: self.firstName1, lastName: self.lastName2)))
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
    }
}