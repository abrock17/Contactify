import Foundation

public class Contact: NSObject, NSCoding, Equatable, Hashable {
    
    public let id: Int32
    public let firstName: String?
    public let lastName: String?
    public let fullName: String!
    public override var description: String {
        return "Contact:[id:\(id), firstName:\(firstName), lastName:\(lastName)]"
    }
    
    public override var hashValue: Int {
        return "\(id)\(firstName)\(lastName)".hashValue
    }
    
    public init(id: Int32, firstName: String?, lastName: String?, fullName: String! = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.fullName = fullName
    }
    
    public required convenience init(coder decoder: NSCoder) {
        let id = decoder.decodeInt32ForKey("id")
        let firstName = decoder.decodeObjectForKey("firstName") as? String?
        let lastName = decoder.decodeObjectForKey("lastName") as? String?
        self.init(id: id, firstName: firstName!, lastName: lastName!, fullName: nil)
    }
    
    public func encodeWithCoder(coder: NSCoder) {
        coder.encodeInt32(self.id, forKey: "id")
        coder.encodeObject(self.firstName, forKey: "firstName")
        coder.encodeObject(self.lastName, forKey: "lastName")
    }
}

public func ==(x: Contact, y: Contact) -> Bool {
    return x.id == y.id || (x.firstName == y.firstName && x.lastName == y.lastName)
}