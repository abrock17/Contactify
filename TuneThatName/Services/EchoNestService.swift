import Foundation
import Alamofire
import SwiftyJSON

public class EchoNestService {
    
    public enum SongResult {
        case Success(Song?)
        case Failure(NSError)
    }
    
    let apiKey = "GVZ7FFJUMMXBG58VQ"
    let songSearchEndpoint = "http://developer.echonest.com/api/v4/song/search"
    let songSearchBuckets = ["tracks", "id:spotify-US"]
    
    let unexpectedResponseMessage = "Unexpected response from the Echo Nest."
    
    let alamoFireManager: Manager!
    
    public init(alamoFireManager: Manager = Manager.sharedInstance) {
        self.alamoFireManager = alamoFireManager
    }
    
    public func findSong(#titleSearchTerm: String!, callback: (SongResult) -> Void) {

        let urlString = buildSongSearchEndpointStringWithBucketParameters() as URLStringConvertible
        let parameters = getParameters(titleSearchTerm: titleSearchTerm)
        
        alamoFireManager.request(.GET, urlString, parameters: parameters).responseJSON {
            (request, response, data, error) in
            
            if let error = error {
                callback(.Failure(error))
            } else if let data: AnyObject = data {
                let json = JSON(data)
                
                let statusJSON = json["response"]["status"]
                if let code = statusJSON["code"].int {
                    if code == 0 {
                        callback(.Success(self.getValidSongFromJSON(json, titleSearchTerm: titleSearchTerm)))
                    } else {
                        callback(.Failure(self.errorForUnexpectedStatusJSON(statusJSON)))
                    }
                } else {
                    callback(.Failure(self.errorForMessage(self.unexpectedResponseMessage, andFailureReason: "No status code in the response.")))
                    println("json : \(json.rawString())")
                }
            } else {
                callback(.Failure(self.errorForMessage(self.unexpectedResponseMessage, andFailureReason: "No data in the response.")))
            }
        }
    }
    
    func getValidSongFromJSON(json: JSON, titleSearchTerm: String!) -> Song? {
        var song: Song?
        
        let jsonSongs = json["response"]["songs"]
        for (index, songJSON: JSON) in jsonSongs {
            if let title = self.getValidMatchingTitle(songJSON, titleSearchTerm: titleSearchTerm) {
                if let uri = self.getValidURI(songJSON) {
                    song = Song(title: title, artistName: songJSON["artist_name"].string, uri: uri)
                    break
                }
            }
        }

        return song
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
                "-\\s.*\(lowercaseSearchTerm).*(remix|edit)"]
            
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
    
    func getParameters(#titleSearchTerm: String) -> [String : AnyObject] {
        return [
            "api_key": apiKey,
            "format": "json",
            "results": 50,
            "limit": "true",
            "title": titleSearchTerm
        ]
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
