import Foundation

public struct SongPreferences: Equatable, Printable {
    
    public var favorPopular: Bool
    public var description: String {
        return "SongPreferences:[favorPopular:\(favorPopular)]"
    }
    
    public init(favorPopular: Bool) {
        self.favorPopular = favorPopular
    }
}

public func ==(x: SongPreferences, y: SongPreferences) -> Bool {
    return x.favorPopular == y.favorPopular
}