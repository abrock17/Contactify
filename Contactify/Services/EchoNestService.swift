import Foundation
import Alamofire
import SwiftyJSON

public class EchoNestService {
    
    let apiKey = "GVZ7FFJUMMXBG58VQ"
    let songSearchEndpoint = "http://developer.echonest.com/api/v4/song/search"
    let songSearchResultLimit = 50
    let songSearchSortValue = "song_hotttnesss-desc"
    let songSearchBuckets = ["tracks", "id:spotify"]
    let limitResultsToCatalog = true
    
    public init() {
    }
    
    public func findSongData(#titleSearchTerm: String!, completionHandler searchCompletionHandler: (SongData?, NSError!) -> Void) {

        var urlString = "\(songSearchEndpoint)?api_key=\(apiKey)&format=json&results=\(songSearchResultLimit)&sort=\(songSearchSortValue)&limit=\(limitResultsToCatalog)&title=\(titleSearchTerm)"
        for bucket in songSearchBuckets {
            urlString += "&bucket=\(bucket)"
        }
        let encodedURLString = urlString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        let request = NSMutableURLRequest(URL: NSURL(string: encodedURLString!)!)
        request.HTTPMethod = "GET"
        let queue = NSOperationQueue()
        
        NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler: {
            (response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
            var songData: SongData?
            
            if data != nil {
                let json = JSON(data: data)
                let songJSON = json["response"]["songs"][0]
                if let title = songJSON["title"].string {
                    songData = SongData(title: title, artistName: songJSON["artist_name"].string, catalogID: nil)
                }
            }
            
            searchCompletionHandler(songData, error)
        })
    }
}
