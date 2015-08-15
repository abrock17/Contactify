import Foundation

public class SongPreferences: NSObject, NSCoding, Equatable {
    
    public var favorPopular: Bool
    public var favorPositive: Bool
    public var favorNegative: Bool
    public override var description: String {
        return "SongPreferences:[favorPopular:\(favorPopular), favorPositive:\(favorPositive), favorNegative:\(favorNegative)]"
    }
    
    public init(favorPopular: Bool, favorPositive: Bool, favorNegative: Bool) {
        self.favorPopular = favorPopular
        self.favorPositive = favorPositive
        self.favorNegative = favorNegative
    }
    
    public required convenience init(coder decoder: NSCoder) {
        let favorPopular = decoder.decodeBoolForKey("favorPopular")
        let favorPositive = decoder.decodeBoolForKey("favorPositive")
        let favorNegative = decoder.decodeBoolForKey("favorNegative")
        self.init(favorPopular: favorPopular, favorPositive: favorPositive, favorNegative: favorNegative)
    }
    
    public func encodeWithCoder(coder: NSCoder) {
        coder.encodeBool(self.favorPopular, forKey: "favorPopular")
        coder.encodeBool(self.favorPositive, forKey: "favorPositive")
        coder.encodeBool(self.favorNegative, forKey: "favorNegative")
    }
}

public func ==(x: SongPreferences, y: SongPreferences) -> Bool {
    return x.favorPopular == y.favorPopular
        && x.favorPositive == y.favorPositive
        && x.favorNegative == y.favorNegative
}