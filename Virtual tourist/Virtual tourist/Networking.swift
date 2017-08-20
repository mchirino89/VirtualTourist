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
    
    static let single = Networking()
    
    // MARK: Initializers
    
    override init() {
        super.init()
    }
    
    // MARK: GET
    
    func taskForGETMethod(serverHost: String, serverPath: String = "", parameters: [String:AnyObject] = [:], isJSON: Bool, completionHandlerForGET: @escaping (_ result: [String:AnyObject]?, _ data: Data?, _ error: NSError?) -> Void) -> URLSessionTask {
        
        var request:NSMutableURLRequest?
        if isJSON {
            let getParametersRequest:[String:AnyObject] = [
                Constants.ParameterKey.method: Constants.ParameterValue.method as AnyObject,
                Constants.ParameterKey.APIKey: Constants.ParameterValue.APIKey as AnyObject,
                Constants.ParameterKey.latitude: parameters[Constants.ParameterKey.latitude]!,
                Constants.ParameterKey.longitude: parameters[Constants.ParameterKey.longitude]!,
                Constants.ParameterKey.format: Constants.ParameterValue.format as AnyObject,
                Constants.ParameterKey.results: Constants.ParameterValue.results as AnyObject,
                Constants.ParameterKey.extra: Constants.ParameterValue.extra as AnyObject,
                Constants.ParameterKey.callback: Constants.ParameterValue.callback as AnyObject,
                Constants.ParameterKey.currentPage: parameters[Constants.ParameterKey.currentPage]!
            ]
            request = NSMutableURLRequest(url: URLFromParameters(host: serverHost, path: serverPath, parameters: getParametersRequest))
        } else {
            let URLStruct = getURLStruct(URL: serverHost)
            request = NSMutableURLRequest(url: URLFromParameters(host: URLStruct.0, path: URLStruct.1, parameters: parameters))
        }
        
        /* 4. Make the request */
        let networkTask = session.dataTask(with: request! as URLRequest) { (data, response, error) in
            
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
        }
        networkTask.resume()
        return networkTask
    }
    
    private func getURLStruct(URL: String) -> (String, String) {
        let mutableURL = URL.replacingOccurrences(of: "https://", with: "").components(separatedBy: "/")
        var path = ""
        for component in mutableURL {
            if !component.contains(".com") {
                path = path + component + "/"
            } else {
                path = "/"
            }
        }
        return (mutableURL.first!, path)
    }
    
    // create a URL from parameters
    private func URLFromParameters(host: String, path: String, parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.APIConfiguration.ApiScheme
        
        components.host = host
        components.path = path
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
