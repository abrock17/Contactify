import Foundation

public struct Song {
    public let title: String!
    public let artistName: String?
    public let catalogID: String?
    
    public init(title: String!, artistName: String?, catalogID: String?) {
        self.title = title
        self.artistName = artistName
        self.catalogID = catalogID
    }
}
