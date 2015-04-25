import Foundation

var capturedRequest: NSURLRequest?
var mockURLProtocolResponseData: NSData?
var mockURLProtocolError: NSError?

class MockURLProtocol: NSURLProtocol {
    
    override class func canInitWithRequest(request: NSURLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
        return request
    }
    
    override class func requestIsCacheEquivalent(aRequest: NSURLRequest,
        toRequest bRequest: NSURLRequest) -> Bool {
            return super.requestIsCacheEquivalent(aRequest, toRequest:bRequest)
    }
    
    override func startLoading() {
        capturedRequest = self.request
        let client = self.client!
        
        if let data = mockURLProtocolResponseData {
            let response = NSURLResponse(URL: self.request.URL!, MIMEType: "application/json", expectedContentLength: -1, textEncodingName: nil)
            client.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: NSURLCacheStoragePolicy.NotAllowed)
            client.URLProtocol(self, didLoadData: data)
            client.URLProtocolDidFinishLoading(self)
        }
        if let error = mockURLProtocolError {
            client.URLProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {
        println("stopLoading")
    }
    
    class func getCapturedRequest() -> NSURLRequest? {
        return capturedRequest
    }
    
    class func setMockResponseData(responseData: NSData!) {
        mockURLProtocolResponseData = responseData
    }
    
    class func setMockError(error: NSError!) {
        mockURLProtocolError = error
    }
    
    class func clear() {
        capturedRequest = nil
        mockURLProtocolResponseData = nil
        mockURLProtocolError = nil
    }
}
