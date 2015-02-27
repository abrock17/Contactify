import Foundation

public class EchoNestService {
    
    let urlConnection: NSURLConnectionWrapper!
    
    public init(urlConnectionWrapper: NSURLConnectionWrapper) {
        self.urlConnection = urlConnectionWrapper
    }
    
    public func findSongData(#titleSearchTerm: String!, completionHandler searchCompletionHandler: (SongData?, NSError!) -> Void) {
        var songData: SongData?
        let urlString : String = "http://developer.echonest.com/api/v4/song/search?api_key=GVZ7FFJUMMXBG58VQ&format=json&results=100&sort=artist_hotttnesss-desc&bucket=tracks&bucket=id:spotify&limit=true&title=\(titleSearchTerm)"
        var request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
        request.HTTPMethod = "GET"
        let queue = NSOperationQueue()
        
        urlConnection.sendAsynchronousRequest(request, queue: queue, completionHandler: { (response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
                searchCompletionHandler(nil, error)
            })
    }
}

public class NSURLConnectionWrapper: NSURLConnection {
    
    public func sendAsynchronousRequest(request: NSURLRequest, queue: NSOperationQueue!, completionHandler handler: (NSURLResponse!, NSData!, NSError!) -> Void) {
        NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler: handler)
    }
}
