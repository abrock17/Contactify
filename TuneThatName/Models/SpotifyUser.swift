import Foundation

public class SpotifyUser: NSObject, NSCoding {
    
    public let username: String
    public let territory: String
    public override var description: String {
        return "SpotifyUser:[username:\(username), territory:\(territory)]"
    }
    
    public init(username: String, territory: String) {
        self.username = username
        self.territory = territory
    }

    public required convenience init(coder decoder: NSCoder) {
        let username = decoder.decodeObjectForKey("username") as! String
        let territory = decoder.decodeObjectForKey("territory") as! String
        self.init(username: username, territory: territory)
    }
    
    public func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(self.username, forKey: "username")
        coder.encodeObject(self.territory, forKey: "territory")
    }
    
    override public func isEqual(object: AnyObject?) -> Bool {
        let equal: Bool
        if let spotifyUser = object as? SpotifyUser {
            equal = self == spotifyUser
        } else {
            equal = false
        }
        
        return equal
    }
}

public func ==(x: SpotifyUser, y: SpotifyUser) -> Bool {
    return x.username == y.username && x.territory == y.territory
}