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

public protocol RequestStatusHandlerProtocol {
    mutating func requestStatus(statusCode code:Int) -> RestAPIResponseCode
    mutating func successfulRequest(forHTTPStatusCode code: Int) -> Bool
}

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
    private(set) var requestStatusHandler: RequestStatusHandlerProtocol
    
    
    init(urlSession: URLSessionProtocol = URLSession.shared, jsonHandler: JSONHandlerProtocol.Type = JSONSerialization.self, requestStatusHandler: RequestStatusHandlerProtocol = RequestStatusHandler()) {
        self.urlSession = urlSession
        self.jsonHandler = jsonHandler
        self.requestStatusHandler = requestStatusHandler
    }
    
    public func postRequest(_ url: URL, title:String, dateTime: Date = Date(), onCompletion: @escaping ServiceResponse) {
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = toDodateFormat
        let postString = "datetime=\(dateFormatter.string(from: dateTime))&taskDetail=\(title)&isFinished=no"
        request.httpBody = postString.data(using: String.Encoding.utf8)
        
        self.beginDataTask(with: request, onCompletion: onCompletion)
    }
    
    public func getRequest(_ url: URL, onCompletion: @escaping ServiceResponse) {
        var request = URLRequest(url: url)
        
        request.httpMethod = "GET"
        
        self.beginDataTask(with: request, onCompletion: onCompletion)
    }
    
    public func patchRequest(_ url: URL, field: String, fieldByValue: String, fieldToChange: String, newValue: String, onCompletion: @escaping ServiceResponse) {
        
        var urlRequest = URLRequest(url: todoEndPointURL.appendingPathComponent("/\(field)/\(fieldByValue)"))
        urlRequest.httpMethod = "PATCH"
        urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let postString = "\(fieldToChange)=\(newValue)"
        urlRequest.httpBody = postString.data(using: String.Encoding.utf8)
        
        self.beginDataTask(with: urlRequest, onCompletion: onCompletion)
    }
    
    public func deleteRequest(_ url: URL, field: String, fieldValue value: String, onCompletion: @escaping ServiceResponse) {
        let urlForDeleteion = url.appendingPathComponent("/\(field)/\(value)")
        var request = URLRequest(url: urlForDeleteion)
        
        request.httpMethod = "DELETE"
        
        self.beginDataTask(with: request, onCompletion: onCompletion)
    }
    
    private func beginDataTask(with request:URLRequest, onCompletion: @escaping ServiceResponse) {
        
        urlSession.dataTask(with: request) { (data, response, dataTaskError) in
            
            if let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == RestAPIResponseCode.deleteSuccessful.rawValue {
                onCompletion(nil,"204 Delete Successful", nil)
                return
            }
            
            let json = try? self.jsonHandler.jsonObject(with: data!, options: [])
            
            let responseString = String(data: data!, encoding: String.Encoding.utf8)
            
            if self.handleErrors(error: dataTaskError, response: response, responseString: responseString, onComplete: onCompletion) { return }
            
            onCompletion(ParSON.create(data: json),responseString, nil)
        }.resume()
    }
    
    private func handleErrors(error: Error?, response: URLResponse?, responseString:String?, onComplete: ServiceResponse) -> Bool
    {
        if error != nil {
            onComplete(nil, responseString, error)
            return true
        }
        else if let httpStatus = response as? HTTPURLResponse,
            !self.requestStatusHandler.successfulRequest(forHTTPStatusCode: httpStatus.statusCode) {
            
            let error = self.requestStatusHandler.requestStatus(statusCode: httpStatus.statusCode)
            
            onComplete(nil, responseString, error)
            return true
        }
        
        return false
    }
}

struct RequestStatusHandler: RequestStatusHandlerProtocol {
    
    func requestStatus(statusCode code: Int) -> RestAPIResponseCode {
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
    
    func successfulRequest(forHTTPStatusCode code: Int) -> Bool {
        return code == 200 || code == 201 || code == 204
    }
}

extension ParSON {
    static func create(data: Any) -> ParSON? {
        var parson: ParSON?
        
        if let jsonDictionary = data as? [String: Any] {
            parson = ParSON(collection: jsonDictionary)
        }
        
        if let jsonArray = data as? [Any] {
            parson = ParSON(collection: jsonArray)
        }
        
        return parson
    }
}
