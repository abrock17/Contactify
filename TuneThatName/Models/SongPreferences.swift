import Foundation

public struct SongPreferences: Equatable {
    
    public var favorPopular: Bool
    
    public init(favorPopular: Bool) {
        self.favorPopular = favorPopular
    }
}

public func ==(x: SongPreferences, y: SongPreferences) -> Bool {
    return x.favorPopular == y.favorPopular
}