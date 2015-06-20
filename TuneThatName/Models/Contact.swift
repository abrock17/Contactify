import Foundation

public struct Contact: Equatable, Hashable, Printable {
    
    public let id: Int32
    public let firstName: String?
    public let lastName: String?
    public let fullName: String!
    public var description: String {
        return "Contact:[id:\(id), firstName:\(firstName), lastName:\(lastName)]"
    }
    
    public var hashValue: Int {
        return "\(id)\(firstName)\(lastName)".hashValue
    }
    
    public init(id: Int32, firstName: String?, lastName: String?, fullName: String! = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.fullName = fullName
    }

}

public func ==(x: Contact, y: Contact) -> Bool {
    return x.id == y.id && x.firstName == y.firstName && x.lastName == y.lastName
}