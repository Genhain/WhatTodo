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
    func dataTask(with request: URLRequest, completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol {
        return (dataTask(with: request, completionHandler: completionHandler) as URLSessionDataTask) as URLSessionDataTaskProtocol
    }
    
    func dataTask(with url: URL, completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol {
        return (dataTask(with: url, completionHandler: completionHandler) as URLSessionDataTask) as URLSessionDataTaskProtocol
    }
}
extension URLSessionDataTask: URLSessionDataTaskProtocol {}

protocol JSONHandlerProtocol {

    static func jsonObject(with data: Data, options opt: JSONSerialization.ReadingOptions) throws -> Any
}

extension JSONSerialization: JSONHandlerProtocol {}

public enum RestAPIResponseCode: Int, Error
{
    case OK = 200
    case postSuccessful = 201
    case deleteSuccessful = 204
    case badRequest = 400
    case unauthorized = 401
    case paymentRequired = 402
    case forbidden = 403
    case notFound = 404
    case rateLimitExceeded = 429
    case serverError = 500
}

public class RestAPI
{
    
    
    public typealias ServiceResponse = (ParSON?, _ responseString: String?, Error?) -> Void
    private(set) var urlSession: URLSessionProtocol
    private(set) var jsonHandler: JSONHandlerProtocol.Type
    
    init(urlSession: URLSessionProtocol = URLSession.shared, jsonHandler: JSONHandlerProtocol.Type = JSONSerialization.self) {
        self.urlSession = urlSession
        self.jsonHandler = jsonHandler
    }
    
    public func postRequest(_ url: URL, id:String, title:String, description:String , onCompletion: @escaping ServiceResponse) {
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        let postString = "id=\(id)&title=\(title)&description=\(description)"
        request.httpBody = postString.data(using: String.Encoding.utf8)
        
        let task = urlSession.dataTask(with: request) { (data, response, dataTaskError) in
            
            let json = try? self.jsonHandler.jsonObject(with: data!, options: [])
            
            let responseString = String(data: data!, encoding: String.Encoding.utf8)
            
            
            if let error = dataTaskError {
                onCompletion(nil, responseString, error)
                return
            }
            else if let httpStatus = response as? HTTPURLResponse,
                        !self.successfulresponse(forHTTPStatusCode: httpStatus.statusCode) {
                
                let error = self.requestError(forHTTPStatusCode: httpStatus.statusCode)
                
                onCompletion(nil, responseString, error)
                return
            }
            
            if let jsonDictionary = json as? [String: Any] {
                onCompletion(ParSON(collection: jsonDictionary), responseString, nil)
                return
            }
            
            if let jsonArray = json as? [Any] {
                onCompletion(ParSON(collection: jsonArray), responseString, nil)
            }

        }
        
        task.resume()
    }
    
    private func successfulresponse(forHTTPStatusCode code: Int) -> Bool {
        return code == 200 || code == 201 || code == 204
    }
    
    private func requestError(forHTTPStatusCode code: Int) -> RestAPIResponseCode {
        
        switch(code){
            
        case RestAPIResponseCode.badRequest.rawValue:
            return RestAPIResponseCode.badRequest
            
        case RestAPIResponseCode.unauthorized.rawValue:
            return RestAPIResponseCode.unauthorized
            
        case RestAPIResponseCode.paymentRequired.rawValue:
            return RestAPIResponseCode.paymentRequired
            
        case RestAPIResponseCode.forbidden.rawValue:
            return RestAPIResponseCode.forbidden
            
        case RestAPIResponseCode.notFound.rawValue:
            return RestAPIResponseCode.notFound
            
        case RestAPIResponseCode.rateLimitExceeded.rawValue:
            return RestAPIResponseCode.rateLimitExceeded
            
        case RestAPIResponseCode.serverError.rawValue:
            return RestAPIResponseCode.serverError
            
        default:
            return RestAPIResponseCode.serverError
        }
    }
}
