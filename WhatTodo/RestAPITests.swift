//
//  RestAPITests.swift
//  WhatTodo
//
//  Created by Ben Fowler on 15/12/2016.
//  Copyright © 2016 BF. All rights reserved.
//

import XCTest
import ParSON
@testable import WhatTodo

enum URLSessionErrorFake: Int, Error
{
    case first = 0
    case second = 1
}

//MARK:Fake
class URLSessionFake: URLSessionProtocol
{
    var testData: [Data]? {  didSet{ dataIterator = (testData?.makeIterator())! } }
    private var dataIterator: IndexingIterator<[Data]>?
    var testError: Error?
    let dataTask = FakeURLSessionDataTask()
    
    private(set) var lastURL: URL?
    
    init(dataToReturn:[Data]?) {
        
        if let data = dataToReturn {
            testData = data
        }
        else {
            self.testData = [try! JSONSerialization.data(withJSONObject: ["Test": "1"], options: .prettyPrinted)]
        }
        
        dataIterator = (testData?.makeIterator())!
    }
    
    func dataTask(with url: URL, completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol {
        lastURL = url
        completionHandler(dataIterator?.next(), nil, testError)
        return dataTask
    }
    
    private(set) var wasDataTaskWithRequestCalled = false
    private(set) var lastRequest: URLRequest?
    
    func dataTask(with request: URLRequest, completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol {
        self.lastRequest = request
        self.wasDataTaskWithRequestCalled = true
        completionHandler(dataIterator?.next(), nil, testError)
        return dataTask
    }
}

class JSONHandlerFake: JSONHandlerProtocol
{
    static private(set) var wasJSonObjectCalled = false
    static private(set) var lastData: Data?
    
    class func jsonObject(with data: Data, options opt: JSONSerialization.ReadingOptions) throws -> Any {
        wasJSonObjectCalled = true
        lastData = data
        return try JSONSerialization.jsonObject(with: data, options: opt)
    }
}

class FakeURLSessionDataTask: URLSessionDataTaskProtocol {
    private (set) var resumeWasCalled = false
    
    func resume() {
        resumeWasCalled = true
    }
}

class RestAPITests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPostRequest_URLSessionFake_dataTaskResumeCalled()
    {
        // Arrange
        let spy = URLSessionFake(dataToReturn: nil)
        let SUT = RestAPI(urlSession: spy)
        
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        
        // Act
        SUT.postRequest(expectedURL, id: "", title: "", description: "") { (parson, response, error) in
            
        }
        
        // Assert
        XCTAssertEqual("POST", spy.lastRequest!.httpMethod!)
        XCTAssertTrue(spy.wasDataTaskWithRequestCalled)
        XCTAssertTrue(spy.dataTask.resumeWasCalled)
    }
    
    func testPostRequest_URLSessionFake_RequestShouldEqualTestDataOne()
    {
        // Arrange
        let expectedData = try? JSONSerialization.data(withJSONObject: ["TestTwo": "2"], options: .prettyPrinted)
        
        guard expectedData != nil else {XCTFail(); return;}
        
        let spy = URLSessionFake(dataToReturn: [expectedData!])
        let SUT = RestAPI(urlSession: spy)
        
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        let expectedID = "0"
        let expectedTitle = "testTitleOne"
        let expectedDescription = "testDescriptionOne"
        
        // Act
        SUT.postRequest(expectedURL, id: expectedID, title: expectedTitle, description: expectedDescription) { (parson, response, error) in
            
        }
    
        // Assert
        XCTAssertEqual(expectedURL, spy.lastRequest?.url)
        XCTAssertEqual("id=\(expectedID)&title=\(expectedTitle)&description=\(expectedDescription)", String(data: spy.lastRequest!.httpBody!, encoding: String.Encoding.utf8))
    }
    
    func testPostRequest_URLSessionFake_RequestShouldEqualTestDataTwo()
    {
        // Arrange
        let expectedData = try? JSONSerialization.data(withJSONObject: ["TestTwo": "2"], options: .prettyPrinted)
        
        guard expectedData != nil else {XCTFail(); return;}
        
        let spy = URLSessionFake(dataToReturn: [expectedData!])
        let SUT = RestAPI(urlSession: spy)
        
        let expectedURL = URL.temporaryURL(forFilename: "Test2")
        let expectedID = "1"
        let expectedTitle = "testTitletwo"
        let expectedDescription = "testDescriptionTwo"
        
        // Act
        SUT.postRequest(expectedURL, id: expectedID, title: expectedTitle, description: expectedDescription) { (parson, response, error) in
            
        }
        
        // Assert
        XCTAssertEqual(expectedURL, spy.lastRequest?.url)
        XCTAssertEqual("id=\(expectedID)&title=\(expectedTitle)&description=\(expectedDescription)", String(data: spy.lastRequest!.httpBody!, encoding: String.Encoding.utf8))
    }
    
    func testPostRequest_JSONHandlerFake_jsonObjectWasCalled()
    {
        // Arrange
        let spy = JSONHandlerFake.self
        let stub = URLSessionFake(dataToReturn: nil)
        let SUT = RestAPI(urlSession: stub, jsonHandler: spy)

        let expectedURL = URL.temporaryURL(forFilename: "Test")

        // Act
        SUT.postRequest(expectedURL, id: "", title: "", description: "") { (parson, response, error) in
            XCTAssertTrue(spy.wasJSonObjectCalled)
        }
    }
    
    func testPostRequest_URLSessionFake_CompletionHandler()
    {
        // Arrange
        let expectedData = try? JSONSerialization.data(withJSONObject: ["Test": "1"], options: .prettyPrinted)
        
        guard expectedData != nil else {XCTFail(); return;}
        
        let spy = URLSessionFake(dataToReturn: [expectedData!])
        let SUT = RestAPI(urlSession: spy, jsonHandler:JSONHandlerFake.self)
        
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        
        // Act
        SUT.postRequest(expectedURL, id: "", title: "", description: "") { (parson, response, error) in
            XCTAssertNotNil(parson)
            XCTAssertEqual("1", try? parson!.value(forKeyPath: "Test") as String)
            XCTAssertEqual(String(data: spy.testData![0], encoding: String.Encoding.utf8), response!)
        }
    }
    
    func testPostRequest_URLSessionFake_ParsonShouldHaveKeyTestTwoEquals2()
    {
        // Arrange
        let expectedData = try? JSONSerialization.data(withJSONObject: ["TestTwo": "2"], options: .prettyPrinted)
        
        guard expectedData != nil else {XCTFail(); return;}
        
        let spy = URLSessionFake(dataToReturn: [expectedData!])
        let SUT = RestAPI(urlSession: spy)
        
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        
        // Act
        SUT.postRequest(expectedURL, id: "", title: "", description: "") { (parson, response, error) in
            XCTAssertNotNil(parson)
            XCTAssertEqual("2", try? parson!.value(forKeyPath: "TestTwo") as String)
            XCTAssertEqual(String(data: spy.testData![0], encoding: String.Encoding.utf8), response!)
        }
    }
    
    func testPostRequest_URLSessionFakeTestDataArray_canParseArrayData()
    {
        // Arrange
        let expectedData = try? JSONSerialization.data(withJSONObject: ["1", "2", "test"], options: .prettyPrinted)
        
        guard expectedData != nil else {XCTFail(); return;}
        
        let spy = URLSessionFake(dataToReturn: [expectedData!])
        let SUT = RestAPI(urlSession: spy)
        
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        
        // Act
        SUT.postRequest(expectedURL, id: "", title: "", description: "") { (parson, response, error) in
            XCTAssertNotNil(parson)
            XCTAssertEqual("1", try? parson!.value(forKeyPath: "[0]") as String)
            XCTAssertEqual("2", try? parson!.value(forKeyPath: "[1]") as String)
            XCTAssertEqual("test", try? parson!.value(forKeyPath: "[2]") as String)
            XCTAssertEqual(String(data: spy.testData![0], encoding: String.Encoding.utf8), response!)
        }
    }
    
    func testPostRequest_URLSessionFakeOtherTestDataArray_canParseArrayData()
    {
        // Arrange
        let expectedData = try? JSONSerialization.data(withJSONObject: ["a", "b", "hello"], options: .prettyPrinted)
        
        guard expectedData != nil else {XCTFail(); return;}
        
        let spy = URLSessionFake(dataToReturn: [expectedData!])
        let SUT = RestAPI(urlSession: spy)
        
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        
        // Act
        SUT.postRequest(expectedURL, id: "", title: "", description: "") { (parson, response, error) in
            XCTAssertNotNil(parson)
            XCTAssertEqual("a", try? parson!.value(forKeyPath: "[0]") as String)
            XCTAssertEqual("b", try? parson!.value(forKeyPath: "[1]") as String)
            XCTAssertEqual("hello", try? parson!.value(forKeyPath: "[2]") as String)
            XCTAssertEqual(String(data: spy.testData![0], encoding: String.Encoding.utf8), response!)
        }
    }
    
    
    func testPostRequest_URLSessionFakeTestErrorTest1_errorIsTest2()
    {
        // Arrange
        let spy = URLSessionFake(dataToReturn: nil)
        let SUT = RestAPI(urlSession: spy)
        
        spy.testError = URLSessionErrorFake.first
        spy.testData = [try! JSONSerialization.data(withJSONObject: ["Test": "1"], options: .prettyPrinted)]
        
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        
        // Act
        SUT.postRequest(expectedURL, id: "", title: "", description: "") { (parson, responseString, error) in
            XCTAssertNil(parson)
            XCTAssertEqual(String(data: spy.testData![0], encoding: String.Encoding.utf8), responseString!)
            XCTAssertEqual(URLSessionErrorFake.first.rawValue, (error as! URLSessionErrorFake).rawValue)
        }
    }
    
    func testPostRequest_URLSessionFakeTestErrorTestTwo2_errorIsTestTwo2()
    {
        // Arrange
        let spy = URLSessionFake(dataToReturn: nil)
        let SUT = RestAPI(urlSession: spy)
        
        spy.testError = URLSessionErrorFake.second
        spy.testData = [try! JSONSerialization.data(withJSONObject: ["TestTwo": "2"], options: .prettyPrinted)]
        
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        
        // Act
        SUT.postRequest(expectedURL, id: "", title: "", description: "") { (parson, responseString, error) in
            XCTAssertNil(parson)
            XCTAssertEqual(String(data: spy.testData![0], encoding: String.Encoding.utf8), responseString!)
            XCTAssertEqual(URLSessionErrorFake.second.rawValue, (error as! URLSessionErrorFake).rawValue)
        }
    }
}
