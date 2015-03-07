import Foundation
import Alamofire
import SwiftyJSON

public class EchoNestService {
    
    public enum SongDataResult {
        case Success(SongData?)
        case Failure(NSError)
    }
    
    let apiKey = "GVZ7FFJUMMXBG58VQ"
    let songSearchEndpoint = "http://developer.echonest.com/api/v4/song/search"
    let songSearchBuckets = ["tracks", "id:spotify"]
    
    let alamoFireManager: Manager!
    
    public init(alamoFireManager: Manager = Manager.sharedInstance) {
        self.alamoFireManager = alamoFireManager
    }
    
    public func findSongData(#titleSearchTerm: String!, completionHandler searchCompletionHandler: (SongDataResult) -> Void) {

        var urlString = buildSongSearchEndpointStringWithBucketParameters()
        
        let parameters: [String: AnyObject] = [
            "api_key": apiKey,
            "format": "json",
            "results": 50,
//            "sort": "song_hotttnesss-desc",
            "limit": "true",
            "title": titleSearchTerm
        ]
        
        alamoFireManager.request(.GET, urlString, parameters: parameters)
            .responseJSON {(request, response, data, error) in
                var songData: SongData?
                
                if let error = error {
                    searchCompletionHandler(.Failure(error))
                } else {
                    var songData: SongData?
                    
                    if let data: AnyObject = data {
                        let json = JSON(data)
                        let jsonSongs = json["response"]["songs"]
                        for (index, songJSON: JSON) in jsonSongs {
                            if let title = self.getValidMatchingTitle(songJSON, titleSearchTerm: titleSearchTerm) {
                                songData = SongData(title: title, artistName: songJSON["artist_name"].string, catalogID: nil)
                                break
                            }
                        }
                    }
                    searchCompletionHandler(.Success(songData))
                }

        }
    }
    
    func getValidMatchingTitle(songJSON: JSON, titleSearchTerm: String!) -> String? {
        var validTitle: String?
        
        if let title = songJSON["title"].string? {
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
