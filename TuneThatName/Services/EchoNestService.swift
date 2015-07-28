import Foundation
import Alamofire
import SwiftyJSON

public class EchoNestService {
    
    public enum SongsResult {
        case Success([Song])
        case Failure(NSError)
    }
    
    static func defaultAlamoFireManager() -> Manager {
        let configuration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = Manager.defaultHTTPHeaders
        configuration.timeoutIntervalForRequest = 10
        configuration.HTTPMaximumConnectionsPerHost = 8
        
        return Manager(configuration: configuration)
    }
    
    let defaultSearchNumber = 50
    let maxResultNumber = 100
    let apiKey = "GVZ7FFJUMMXBG58VQ"
    let songSearchEndpoint = "http://developer.echonest.com/api/v4/song/search"
    let songSearchBuckets = ["tracks", "id:spotify-US", "song_discovery", "artist_discovery"]
    
    let unexpectedResponseMessage = "Unexpected response from the Echo Nest."
    
    let alamoFireManager: Manager!
    
    public init(alamoFireManager: Manager = EchoNestService.defaultAlamoFireManager()) {
        self.alamoFireManager = alamoFireManager
    }
    
    public func findSongs(#titleSearchTerm: String, songPreferences: SongPreferences, desiredNumberOfSongs: Int, callback: (SongsResult) -> Void) {
        
        let urlString = buildSongSearchEndpointStringWithBucketParameters() as URLStringConvertible
        let parameters = getSongSearchParameters(titleSearchTerm: titleSearchTerm, songPreferences: songPreferences, desiredNumberOfSongs: desiredNumberOfSongs)
        
        alamoFireManager.request(.GET, urlString, parameters: parameters).responseJSON {
            (request, response, data, error) in
            
            if let error = error {
                println("request url : \(request.URL) \nresponse status code : \(response?.statusCode) \nheaders : \(response?.allHeaderFields)")
                callback(.Failure(error))
            } else if let data: AnyObject = data {
                let json = JSON(data)
                
                let statusJSON = json["response"]["status"]
                if let code = statusJSON["code"].int {
                    if code == 0 {
                        callback(.Success(self.getValidSongsFromJSON(json, titleSearchTerm: titleSearchTerm, songPreferences: songPreferences, desiredNumberOfSongs: desiredNumberOfSongs)))
                    } else {
                        callback(.Failure(self.errorForUnexpectedStatusJSON(statusJSON)))
                    }
                } else {
                    println("json : \(json.rawString())")
                    callback(.Failure(self.errorForMessage(self.unexpectedResponseMessage, andFailureReason: "No status code in the response.")))
                }
            } else {
                println("request url : \(request.URL) \nresponse status code : \(response?.statusCode) \nheaders : \(response?.allHeaderFields)")
                callback(.Failure(self.errorForMessage(self.unexpectedResponseMessage, andFailureReason: "No data in the response.")))
            }
        }
    }
    
    func getValidSongsFromJSON(json: JSON, titleSearchTerm: String, songPreferences: SongPreferences, desiredNumberOfSongs: Int) -> [Song] {
        var songs = [Song]()
        var artistIDs = [String]()
        
        let jsonSongs = json["response"]["songs"].arrayValue
        let sortedSongs = sortForSongPreferences(jsonSongs, songPreferences: songPreferences)
        for (songJSON: JSON) in sortedSongs {
            if let title = self.getValidMatchingTitle(songJSON, titleSearchTerm: titleSearchTerm) {
                let artistID = songJSON["artist_id"].stringValue
                if !contains(artistIDs, artistID) {
                    if let uri = self.getValidURI(songJSON) {
                        songs.append(Song(title: title, artistName: songJSON["artist_name"].string, uri: uri))
                        artistIDs.append(artistID)
                        if (songs.count == desiredNumberOfSongs) {
                            break
                        }
                    }
                }
            }
        }
        
        return songs
    }
    
    func sortForSongPreferences(jsonSongs: [JSON], songPreferences: SongPreferences) -> [JSON] {
        let sortedJSONSongs: [JSON]
        
        if !songPreferences.favorPopular {
            sortedJSONSongs = sorted(jsonSongs,
                { self.combineSongAndArtistDiscoveryValue($0) > self.combineSongAndArtistDiscoveryValue($1) })
        } else {
            sortedJSONSongs = jsonSongs
        }
        
        return sortedJSONSongs
    }
    
    func combineSongAndArtistDiscoveryValue(songJSON: JSON) -> Float {
        var discoveryValue: Float
        if let songDiscovery = songJSON["song_discovery"].float {
            discoveryValue = songDiscovery * 250
            if let artistDiscovery = songJSON["artist_discovery"].float {
                discoveryValue += artistDiscovery
            }
        } else {
            discoveryValue = 0
        }

        return discoveryValue
    }
    
    func getValidMatchingTitle(songJSON: JSON, titleSearchTerm: String!) -> String? {
        var validTitle: String?
        
        if let title = songJSON["title"].string {
            var valid = true
            let lowercaseTitle = title.lowercaseString
            let lowercaseSearchTerm = titleSearchTerm.lowercaseString
            let exclusionExpressions = [
                "feat.*\(lowercaseSearchTerm)",
                "\\(.*\(lowercaseSearchTerm).*\\)",
                "-\\s.*\(lowercaseSearchTerm).*(remix|edit)",
                "curated by.*\(lowercaseSearchTerm).*"]
            
            for regex in exclusionExpressions {
                if lowercaseTitle.rangeOfString(regex, options: .RegularExpressionSearch) != nil {
                    valid = false
                    break
                }
            }
            
            validTitle = valid ? title : nil
        }
        
        return validTitle
    }
    
    func getValidURI(songJSON: JSON) -> NSURL? {
        var uri: NSURL?
        
        if let uriStringWithLocale = songJSON["tracks"][0]["foreign_id"].string {
            var uriString = uriStringWithLocale.stringByReplacingOccurrencesOfString("-US", withString: "")
            uri = NSURL(string: uriString)
        }
        
        return uri
    }
    
    func errorForUnexpectedStatusJSON(statusJSON: JSON) -> NSError {
        var statusMessage: String!
        let message = statusJSON["message"].string
        if let message = message {
            statusMessage = message
        } else {
            statusMessage = "[no message]"
        }
        return errorForMessage("Non-zero status code from the Echo Nest.", andFailureReason: statusMessage)
    }
    
    func errorForMessage(message: String, andFailureReason reason: String) -> NSError {
        return NSError(domain: Constants.Error.Domain, code: 0, userInfo: [NSLocalizedDescriptionKey: message, NSLocalizedFailureReasonErrorKey: reason])
    }
    
    func getSongSearchParameters(#titleSearchTerm: String, songPreferences: SongPreferences, desiredNumberOfSongs: Int) -> [String : AnyObject] {
        var parameters: [String: AnyObject] = [
            "api_key": apiKey,
            "format": "json",
            "results": getResultParameter(desiredNumberOfSongs: desiredNumberOfSongs),
            "limit": "true",
            "title": titleSearchTerm
        ]
        
        if songPreferences.favorPopular {
            parameters["sort"] = "song_hotttnesss-desc"
        }
        
        return parameters
    }
    
    func getResultParameter(#desiredNumberOfSongs: Int) -> Int {
        let resultNumber: Int
        if desiredNumberOfSongs > defaultSearchNumber / 2 {
            if maxResultNumber < desiredNumberOfSongs * 2 {
                resultNumber = maxResultNumber
            } else {
                resultNumber = desiredNumberOfSongs * 2
            }
        } else {
            resultNumber = defaultSearchNumber
        }
        
        return resultNumber
    }
    
    func buildSongSearchEndpointStringWithBucketParameters() -> String! {
        var urlString = "\(songSearchEndpoint)?"
        var separator = ""
        for bucket in songSearchBuckets {
            urlString += "\(separator)bucket=\(bucket)"
            separator = "&"
        }
        return urlString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
    }
}
