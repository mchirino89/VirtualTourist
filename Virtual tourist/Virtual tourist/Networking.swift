//
//  Networking.swift
//  UdacityMap
//
//  Created by Mauricio Chirino on 28/7/17.
//  Copyright © 2017 3CodeGeeks. All rights reserved.
//

import UIKit

class Networking: NSObject {
    
    let session = URLSession.shared

    // authentication state
    var sessionID: String? = nil
    var userID: Int? = nil
    
    // MARK: Initializers
    
    override init() {
        super.init()
    }
    
    // MARK: GET
    
    func taskForGETMethod(parameters: [String:AnyObject], jsonBody: String, completionHandlerForGET: @escaping (_ result: [String:AnyObject]?, _ error: NSError?) -> Void) {
        
        /* 2/3. Build the URL, Configure the request */
        
        let request = NSMutableURLRequest(url: URLFromParameters(parameters: parameters))
        
        print(request.url ?? "No url")
        
        /* 4. Make the request */
        session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForGET(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                sendError("\(Constants.ErrorMessages.generic)\(error!)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError(Constants.ErrorMessages.noSuccess)
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError(Constants.ErrorMessages.noData)
                return
            }
            
            /* 5/6. Parse the data and use the data (happens in completion handler) */
            self.convertDataWithCompletionHandler(data, completionHandlerForConvertData: completionHandlerForGET)
        }.resume()
    }
    
    // MARK: Network logic for Http request
    private func networkLogic(logicHandler: @escaping (Data?, URLResponse?, Error?) -> Void, completionHandlerForRequest: @escaping (_ result: [String:AnyObject]?, _ error: NSError?) -> Void) {
        // ⚠️ I wanted to move the logic from http request into here but i didn't find a way to execute the closeru 'logicHandler' within this method. Could you please tell me how to do it?
//        logicHandler() {
//            (data, response, error) in
//        }
    }
    
    // given raw JSON, return a usable Foundation object
    private func convertDataWithCompletionHandler(_ data: Data, completionHandlerForConvertData: (_ result: [String:AnyObject]?, _ error: NSError?) -> Void) {
        
        var parsedResult: AnyObject! = nil
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "\(Constants.ErrorMessages.parsingJSON)'\(data)'"]
            completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandlerForConvertData(parsedResult as? [String : AnyObject], nil)
    }
    
    // create a URL from parameters
    private func URLFromParameters(parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.APIConfiguration.ApiScheme
        
        components.host = "api.flickr.com"
        components.path = "/services/rest/"
        components.queryItems = [URLQueryItem]()
        
        for (key, pairValue) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(pairValue)")
            components.queryItems!.append(queryItem)
        }
        return components.url!
    }
    
    class func sharedInstance() -> Networking {
        struct Singleton {
            static var sharedInstance = Networking()
        }
        return Singleton.sharedInstance
    }
}
