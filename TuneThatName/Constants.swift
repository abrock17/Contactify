import Foundation

public struct Constants {
    
    public struct Error {
        public static let Domain = "com.mcsearchin.TuneThatName"
        
        public static let AddressBookNoAccessCode = 10
        public static let AddressBookNoAccessMessage = "This application is not allowed to access Contacts."
        
        public static let NoContactsCode = 15
        public static let NoContactsMessage = "You currently have no contacts."
        
        public static let PlaylistGeneralErrorCode = 20
        public static let PlaylistGeneralErrorMessage = "Encountered errors trying to build your playlist."
        
        public static let PlaylistNotEnoughSongsCode = 21
        public static let PlaylistNotEnoughSongsMessage = "Could not find enough songs matching the provided search criteria."

        public static let SpotifyNoCurrentTrackCode = 25
        public static let SpotifyNoCurrentTrackMessage = "There is no track in the current session."
    }
    
    public struct StorageKeys {
        public static let filteredContacts = "TuneThatName.contacts.filtered"
        public static let playlistPreferences = "TuneThatName.playlist.preferences"
    }
}