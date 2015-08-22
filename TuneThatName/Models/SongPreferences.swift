import Foundation

public class SongPreferences: NSObject, NSCoding, Equatable {
    
    public enum Characteristic: String, Printable {
        case Popular = "Popular"
        case Positive = "Positive"
        case Negative = "Negative"
        case Energetic = "Energetic"
        case Chill = "Chill"
        public var description: String {
            return rawValue
        }
    }
    
    public var characteristics = Set<Characteristic>()
    public override var description: String {
        return "SongPreferences:[characteristics:\(characteristics)]"
    }
    
    public init(characteristics: Set<Characteristic> = Set<SongPreferences.Characteristic>([])) {
        self.characteristics = characteristics
    }
    
    public required convenience init(coder decoder: NSCoder) {
        var characteristics = Set<Characteristic>()
        let characteristicsObject: AnyObject? = decoder.decodeObjectForKey("characteristics")
        if let characteristicStrings = characteristicsObject as? [String] {
            characteristics.unionInPlace(characteristicStrings.map({ Characteristic(rawValue: $0) }).filter({ $0 != nil }).map({ $0! }))
        }
        self.init(characteristics: characteristics)
    }
    
    public func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(Array(characteristics).map({ $0.rawValue }), forKey: "characteristics")
    }
}

public func ==(x: SongPreferences, y: SongPreferences) -> Bool {
    return x.characteristics == y.characteristics
}