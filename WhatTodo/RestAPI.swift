//
//  RestAPI.swift
//  WhatTodo
//
//  Created by Ben Fowler on 15/12/2016.
//  Copyright © 2016 BF. All rights reserved.
//

import Foundation
import ParSON

typealias DataTaskResult = (Data?, URLResponse?, Error?) -> Swift.Void

protocol URLSessionDataTaskProtocol {
    func resume()
}

protocol URLSessionProtocol {
    
    func dataTask(with url: URL, completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol
    
    func dataTask(with request: URLRequest, completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol
}

extension URLSession: URLSessionProtocol {
    internal func dataTask(with request: URLRequest, completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol {
        return (dataTask(with: request, completionHandler: completionHandler) as URLSessionDataTask) as URLSessionDataTaskProtocol
    }
    
    func dataTask(with url: URL, completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol {
        return (dataTask(with: url, completionHandler: completionHandler) as URLSessionDataTask) as URLSessionDataTaskProtocol
    }
}
extension URLSessionDataTask: URLSessionDataTaskProtocol {}

class RestAPI
{
    public typealias ServiceResponse = (ParSON?, URLResponse?, Error?) -> Void
    private(set) var urlSession: URLSessionProtocol
    
    init(urlSession: URLSessionProtocol) {
        self.urlSession = urlSession
    }
    
//    func postRequest(id:String, title:String, description:String , onCompletion: @escaping ServiceResponse) {
        //        if let url = URL(string: "https://sheetsu.com/apis/v1.0/6e59b7bf3d94") {
        //
        //            let request = NSMutableURLRequest(url: url)
        //            request.httpMethod = "POST"
        //            let postString = "id=\(id)&title=\(title)&description=\(description)"
        //            request.httpBody = postString.data(using: String.Encoding.utf8)
        //            let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
        //                guard error == nil && data != nil else {
        //                    // check for fundamental networking error
        //                    print("error=\(error)")
        //                    return
        //                }
        //
        //                if let httpStatus = response as? HTTPURLResponse , httpStatus.statusCode != 200 {           // check for http errors
        //                    print("statusCode should be 200, but is \(httpStatus.statusCode)")
        //                    print("response = \(response)")
        //                }
        //
        //                let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
        //                if let jsonData = data
        //                {
        //                    let json = try? JSONSerialization.jsonObject(with: jsonData, options: [.mutableContainers])
        //
        //                    if let jsonArray = json as? [Any] {
        //                        onCompletion(ParSON(collection: jsonArray), nil)
        //                    }
        //
        //                    if let jsonDictionary = json as? [String: Any] {
        //                        onCompletion(ParSON(collection: jsonDictionary), nil)
        //                    }
        //                    
        //                } else {
        //                    onCompletion(nil, error)
        //                }
        //            }
        //            task.resume()
        //        }
        //    }
    
    public func postRequest(id:String, title:String, description:String , onCompletion: @escaping ServiceResponse) {
        
        urlSession.dataTask(with: URLRequest.init(url: URL.temporaryURL(forFilename: ""))) { (data, response, error) in
            
        }.resume()
    }
}
