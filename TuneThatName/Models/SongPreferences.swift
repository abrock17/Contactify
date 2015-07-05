import Foundation

public class SongPreferences: NSObject, NSCoding, Equatable {
    
    public var favorPopular: Bool
    public override var description: String {
        return "SongPreferences:[favorPopular:\(favorPopular)]"
    }
    
    public init(favorPopular: Bool) {
        self.favorPopular = favorPopular
    }
    
    public required convenience init(coder decoder: NSCoder) {
        let favorPopular = decoder.decodeBoolForKey("favorPopular")
        self.init(favorPopular: favorPopular)
    }
    
    public func encodeWithCoder(coder: NSCoder) {
        coder.encodeBool(self.favorPopular, forKey: "favorPopular")
    }
}

public func ==(x: SongPreferences, y: SongPreferences) -> Bool {
    return x.favorPopular == y.favorPopular
}