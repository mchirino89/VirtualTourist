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
    
    // MARK: Initializers
    
    override init() {
        super.init()
    }
    
    // MARK: GET
    
    func taskForGETMethod(parameters: [String:AnyObject], isJSON: Bool, completionHandlerForGET: @escaping (_ result: [String:AnyObject]?, _ data: Data?, _ error: NSError?) -> Void) {
        
        let request = NSMutableURLRequest(url: URLFromParameters(parameters: parameters))
        
        /* 4. Make the request */
        session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForGET(nil, nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
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
            
            self.convertDataWithCompletionHandler(data, dataType: isJSON, completionHandlerForConvertData: completionHandlerForGET)
        }.resume()
    }
    
    // create a URL from parameters
    private func URLFromParameters(parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.APIConfiguration.ApiScheme
        
        components.host = Constants.URL.host
        components.path = Constants.URL.path
        components.queryItems = [URLQueryItem]()
        
        for (key, pairValue) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(pairValue)")
            components.queryItems!.append(queryItem)
        }
        return components.url!
    }
    
    // given raw JSON, return a usable Foundation object
    private func convertDataWithCompletionHandler(_ data: Data, dataType: Bool, completionHandlerForConvertData: (_ result: [String:AnyObject]?, _ data: Data?, _ error: NSError?) -> Void) {
        
        if dataType {
            var parsedResult: AnyObject! = nil
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
            } catch {
                let userInfo = [NSLocalizedDescriptionKey : "\(Constants.ErrorMessages.parsingJSON)'\(data)'"]
                completionHandlerForConvertData(nil, nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
            }
            completionHandlerForConvertData(parsedResult as? [String : AnyObject], nil, nil)
        } else {
            completionHandlerForConvertData(nil, data, nil)
        }
    }
    
    class func sharedInstance() -> Networking {
        struct Singleton {
            static var sharedInstance = Networking()
        }
        return Singleton.sharedInstance
    }
}
