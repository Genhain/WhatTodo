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
    var testData: [Data]? {  didSet{ if testData != nil{ dataIterator = (testData?.makeIterator())! } else { dataIterator = nil } } }
    private var dataIterator: IndexingIterator<[Data]>?
    var testError: Error?
    let dataTask = FakeURLSessionDataTask()
    var testURLResponse: URLResponse?
    
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
        completionHandler(dataIterator?.next(), testURLResponse, testError)
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

class RequestStatusHandlerFake: RequestStatusHandlerProtocol {
    
    private(set) var wasReqestStatusCalled = false
    private(set) var wasSuccessfulResponseCalled = false
    var stubRequestStatus: RestAPIResponseCode = RestAPIResponseCode.OK
    
    public func requestStatus(statusCode code: Int) -> RestAPIResponseCode {
        self.wasReqestStatusCalled = true
        return stubRequestStatus
    }
    
    public func successfulRequest(forHTTPStatusCode code: Int) -> Bool {
        self.wasSuccessfulResponseCalled = true
        return false
    }
}

class RestAPITests: XCTestCase {
    
    var spy: URLSessionFake?
    var SUT: RestAPI?
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        spy = URLSessionFake(dataToReturn: nil)
        SUT = RestAPI(urlSession: spy!)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    //MARK: POST tests
    func testPostRequest_URLSessionFake_dataTaskResumeCalled()
    {
        // Arrange
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        
        // Act
        
        SUT!.postRequest(expectedURL, title: "") { (parson, response, error) in
            
        }
        
        // Assert
        XCTAssertEqual("POST", spy!.lastRequest!.httpMethod!)
        XCTAssertTrue(spy!.wasDataTaskWithRequestCalled)
        XCTAssertTrue(spy!.dataTask.resumeWasCalled)
    }
    
    func testPostRequest_URLSessionFake_RequestShouldEqualTestDataOne()
    {
        // Arrange
        let expectedData = try? JSONSerialization.data(withJSONObject: ["TestTwo": "2"], options: .prettyPrinted)
        
        guard expectedData != nil else {XCTFail(); return;}
        
        spy = URLSessionFake(dataToReturn: [expectedData!])
        SUT = RestAPI(urlSession: spy!)
        
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        let expectedDate = Date()
        let expectedTitle = "testTitleOne"
        
        // Act
        SUT!.postRequest(expectedURL, title: expectedTitle) { (parson, response, error) in
            
        }
    
        // Assert
        XCTAssertEqual(expectedURL, spy!.lastRequest?.url)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm:ss zzzz"
        XCTAssertEqual("datetime=\(dateFormatter.string(from: expectedDate))&taskDetail=\(expectedTitle)&isFinished=no", String(data: spy!.lastRequest!.httpBody!, encoding: String.Encoding.utf8))
    }
    
    func testPostRequest_URLSessionFake_RequestShouldEqualTestDataTwo()
    {
        // Arrange
        let expectedData = try? JSONSerialization.data(withJSONObject: ["TestTwo": "2"], options: .prettyPrinted)
        
        guard expectedData != nil else {XCTFail(); return;}
        
        spy = URLSessionFake(dataToReturn: [expectedData!])
        SUT = RestAPI(urlSession: spy!)
        
        let expectedURL = URL.temporaryURL(forFilename: "Test2")
        let expectedDate = Date.init(timeIntervalSinceNow: 1000)
        let expectedTitle = "testTitletwo"
        
        // Act
        SUT!.postRequest(expectedURL, title: expectedTitle, dateTime: expectedDate) { (parson, response, error) in
            
        }
        
        // Assert
        XCTAssertEqual(expectedURL, spy?.lastRequest?.url)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm:ss zzzz"
        XCTAssertEqual("datetime=\(dateFormatter.string(from: expectedDate))&taskDetail=\(expectedTitle)&isFinished=no", String(data: spy!.lastRequest!.httpBody!, encoding: String.Encoding.utf8))
    }
    
    func testPostRequest_JSONHandlerFake_jsonObjectWasCalled()
    {
        // Arrange
        let spy = JSONHandlerFake.self
        let stub = URLSessionFake(dataToReturn: nil)
        SUT = RestAPI(urlSession: stub, jsonHandler: spy)

        let expectedURL = URL.temporaryURL(forFilename: "Test")

        // Act
        SUT!.postRequest(expectedURL, title: "") { (parson, response, error) in
            XCTAssertTrue(spy.wasJSonObjectCalled)
        }
    }
    
    func testPostRequest_URLSessionFake_CompletionHandler()
    {
        // Arrange
        let expectedData = try? JSONSerialization.data(withJSONObject: ["Test": "1"], options: .prettyPrinted)
        
        guard expectedData != nil else {XCTFail(); return;}
        
        spy = URLSessionFake(dataToReturn: [expectedData!])
        SUT = RestAPI(urlSession: spy!, jsonHandler:JSONHandlerFake.self)
        
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        
        // Act
        SUT!.postRequest(expectedURL, title: "") { (parson, response, error) in
            XCTAssertNotNil(parson)
            XCTAssertEqual("1", try? parson!.value(forKeyPath: "Test") as String)
            XCTAssertEqual(String(data: self.spy!.testData![0], encoding: String.Encoding.utf8), response!)
        }
    }
    
    func testPostRequest_URLSessionFake_ParsonShouldHaveKeyTestTwoEquals2()
    {
        // Arrange
        let expectedData = try? JSONSerialization.data(withJSONObject: ["TestTwo": "2"], options: .prettyPrinted)
        
        guard expectedData != nil else {XCTFail(); return;}
        
        spy = URLSessionFake(dataToReturn: [expectedData!])
        SUT = RestAPI(urlSession: spy!)
        
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        
        // Act
        SUT!.postRequest(expectedURL, title: "") { (parson, response, error) in
            XCTAssertNotNil(parson)
            XCTAssertEqual("2", try? parson!.value(forKeyPath: "TestTwo") as String)
            XCTAssertEqual(String(data: self.spy!.testData![0], encoding: String.Encoding.utf8), response!)
        }
    }
    
    func testPostRequest_URLSessionFakeTestDataArray_canParseArrayData()
    {
        // Arrange
        let expectedData = try? JSONSerialization.data(withJSONObject: ["1", "2", "test"], options: .prettyPrinted)
        
        guard expectedData != nil else {XCTFail(); return;}
        
        spy = URLSessionFake(dataToReturn: [expectedData!])
        SUT = RestAPI(urlSession: spy!)
        
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        
        // Act
        SUT!.postRequest(expectedURL, title: "") { (parson, response, error) in
            XCTAssertNotNil(parson)
            XCTAssertEqual("1", try? parson!.value(forKeyPath: "[0]") as String)
            XCTAssertEqual("2", try? parson!.value(forKeyPath: "[1]") as String)
            XCTAssertEqual("test", try? parson!.value(forKeyPath: "[2]") as String)
            XCTAssertEqual(String(data: self.spy!.testData![0], encoding: String.Encoding.utf8), response!)
        }
    }
    
    func testPostRequest_URLSessionFakeOtherTestDataArray_canParseArrayData()
    {
        // Arrange
        let expectedData = try? JSONSerialization.data(withJSONObject: ["a", "b", "hello"], options: .prettyPrinted)
        
        guard expectedData != nil else {XCTFail(); return;}
        
        spy = URLSessionFake(dataToReturn: [expectedData!])
        SUT = RestAPI(urlSession: spy!)
        
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        
        // Act
        SUT!.postRequest(expectedURL, title: "") { (parson, response, error) in
            XCTAssertNotNil(parson)
            XCTAssertEqual("a", try? parson!.value(forKeyPath: "[0]") as String)
            XCTAssertEqual("b", try? parson!.value(forKeyPath: "[1]") as String)
            XCTAssertEqual("hello", try? parson!.value(forKeyPath: "[2]") as String)
            XCTAssertEqual(String(data: self.spy!.testData![0], encoding: String.Encoding.utf8), response!)
        }
    }
    
    
    func testPostRequest_URLSessionFakeTestErrorTest1_errorIsTest1()
    {
        // Arrange
        spy!.testError = URLSessionErrorFake.first
        spy!.testData = [try! JSONSerialization.data(withJSONObject: ["Test": "1"], options: .prettyPrinted)]
        
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        
        // Act
        SUT!.postRequest(expectedURL, title: "") { (parson, responseString, error) in
            XCTAssertNil(parson)
            XCTAssertEqual(String(data: self.spy!.testData![0], encoding: String.Encoding.utf8), responseString!)
            XCTAssertEqual(URLSessionErrorFake.first.rawValue, (error as! URLSessionErrorFake).rawValue)
        }
    }
    
    func testPostRequest_URLSessionFakeTestErrorTestTwo2_errorIsTestTwo2()
    {
        // Arrange
        spy!.testError = URLSessionErrorFake.second
        spy!.testData = [try! JSONSerialization.data(withJSONObject: ["TestTwo": "2"], options: .prettyPrinted)]
        
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        
        // Act
        SUT!.postRequest(expectedURL, title: "") { (parson, responseString, error) in
            XCTAssertNil(parson)
            XCTAssertEqual(String(data: self.spy!.testData![0], encoding: String.Encoding.utf8), responseString!)
            XCTAssertEqual(URLSessionErrorFake.second.rawValue, (error as! URLSessionErrorFake).rawValue)
        }
    }
    
    func testPostRequest_HTTPStatusCode400_ReturnError()
    {
        // Arrange
        spy!.testURLResponse = HTTPURLResponse.init(url: URL.temporaryURL(forFilename: ""), statusCode: RestAPIResponseCode.badRequest.rawValue, httpVersion: nil, headerFields: nil)
        
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        
        // Act
        SUT!.postRequest(expectedURL, title: "") { (parson, responseString, error) in
            XCTAssertNil(parson)
            XCTAssertEqual(RestAPIResponseCode.badRequest, (error as! RestAPIResponseCode))
        }
    }
    
    func testPostRequest_HTTPStatusCode401_ReturnError()
    {
        // Arrange
        spy!.testURLResponse = HTTPURLResponse.init(url: URL.temporaryURL(forFilename: ""), statusCode: RestAPIResponseCode.unauthorized.rawValue, httpVersion: nil, headerFields: nil)
        
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        
        // Act
        SUT!.postRequest(expectedURL, title: "") { (parson, responseString, error) in
            XCTAssertNil(parson)
            XCTAssertEqual(RestAPIResponseCode.unauthorized, (error as! RestAPIResponseCode))
        }
    }
    
    func testPostRequest_HTTPStatusCode402_ReturnError()
    {
        // Arrange
        spy!.testURLResponse = HTTPURLResponse.init(url: URL.temporaryURL(forFilename: ""), statusCode: RestAPIResponseCode.paymentRequired.rawValue, httpVersion: nil, headerFields: nil)
        
        
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        
        // Act
        SUT!.postRequest(expectedURL, title: "") { (parson, responseString, error) in
            XCTAssertNil(parson)
            XCTAssertEqual(RestAPIResponseCode.paymentRequired, (error as! RestAPIResponseCode))
        }
    }
    
    func testPostRequest_HTTPStatusCode403_ReturnError()
    {
        // Arrange
        spy!.testURLResponse = HTTPURLResponse.init(url: URL.temporaryURL(forFilename: ""), statusCode: RestAPIResponseCode.forbidden.rawValue, httpVersion: nil, headerFields: nil)
        
        
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        
        // Act
        SUT!.postRequest(expectedURL, title: "") { (parson, responseString, error) in
            XCTAssertNil(parson)
            XCTAssertEqual(RestAPIResponseCode.forbidden, (error as! RestAPIResponseCode))
        }
    }
    
    func testPostRequest_HTTPStatusCode404_ReturnError()
    {
        // Arrange
        spy!.testURLResponse = HTTPURLResponse.init(url: URL.temporaryURL(forFilename: ""), statusCode: RestAPIResponseCode.notFound.rawValue, httpVersion: nil, headerFields: nil)
        
        
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        
        // Act
        SUT!.postRequest(expectedURL, title: "") { (parson, responseString, error) in
            XCTAssertNil(parson)
            XCTAssertEqual(RestAPIResponseCode.notFound, (error as! RestAPIResponseCode))
        }
    }
    
    func testPostRequest_HTTPStatusCode429_ReturnError()
    {
        // Arrange
        spy!.testURLResponse = HTTPURLResponse.init(url: URL.temporaryURL(forFilename: ""), statusCode: RestAPIResponseCode.rateLimitExceeded.rawValue, httpVersion: nil, headerFields: nil)
        
        
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        
        // Act
        SUT!.postRequest(expectedURL, title: "") { (parson, responseString, error) in
            XCTAssertNil(parson)
            XCTAssertEqual(RestAPIResponseCode.rateLimitExceeded, (error as! RestAPIResponseCode))
        }
    }
    
    func testPostRequest_HTTPStatusCode500_ReturnError()
    {
        // Arrange
        spy!.testURLResponse = HTTPURLResponse.init(url: URL.temporaryURL(forFilename: ""), statusCode: RestAPIResponseCode.serverError.rawValue, httpVersion: nil, headerFields: nil)
        
        
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        
        // Act
        SUT!.postRequest(expectedURL, title: "") { (parson, responseString, error) in
            XCTAssertNil(parson)
            XCTAssertEqual(RestAPIResponseCode.serverError, (error as! RestAPIResponseCode))
        }
    }
    
    func testPostRequest_HTTPStatusCodeNegative100_ReturnServerError()
    {
        // Arrange
        spy!.testURLResponse = HTTPURLResponse.init(url: URL.temporaryURL(forFilename: ""), statusCode: -100, httpVersion: nil, headerFields: nil)
        
        
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        
        // Act
        SUT!.postRequest(expectedURL, title: "") { (parson, responseString, error) in
            XCTAssertNil(parson)
            XCTAssertEqual(RestAPIResponseCode.serverError, (error as! RestAPIResponseCode))
        }
    }
    
    func testPostRequest_HTTPStatusCode200_ParSONNotNIL()
    {
        // Arrange
        spy!.testURLResponse = HTTPURLResponse.init(url: URL.temporaryURL(forFilename: ""), statusCode: RestAPIResponseCode.OK.rawValue, httpVersion: nil, headerFields: nil)
        
        
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        
        // Act
        SUT!.postRequest(expectedURL, title: "") { (parson, responseString, error) in
            XCTAssertNotNil(parson)
            XCTAssertNil(error)
        }
    }
    
    func testPostRequest_HTTPStatusCode201_ParSONNotNIL()
    {
        // Arrange
        spy!.testURLResponse = HTTPURLResponse.init(url: URL.temporaryURL(forFilename: ""), statusCode: RestAPIResponseCode.postSuccessful.rawValue, httpVersion: nil, headerFields: nil)
        
        
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        
        // Act
        SUT!.postRequest(expectedURL, title: "") { (parson, responseString, error) in
            XCTAssertNotNil(parson)
            XCTAssertNil(error)
        }
    }
    
    func testPostRequest_HTTPStatusCode204_ParSONNotNIL()
    {
        // Arrange
        spy!.testURLResponse = HTTPURLResponse.init(url: URL.temporaryURL(forFilename: ""), statusCode: RestAPIResponseCode.deleteSuccessful.rawValue, httpVersion: nil, headerFields: nil)
        
        
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        
        // Act
        SUT!.postRequest(expectedURL, title: "") { (parson, responseString, error) in
            XCTAssertNil(parson)
            XCTAssertNil(error)
        }
    }
    
    //MARK: GET Tests
    
    func testGetRequest_FakeDataSession_VerifyConstantsAndMethodCalls()
    {
        // Arrange
        let expectedURL = URL.temporaryURL(forFilename: "")
    
        // Act
        // Assert
        var didCallClosure = false
        SUT!.getRequest(expectedURL) { parSON, responseString, error in
            
            didCallClosure = true
        }
        
        XCTAssertTrue(didCallClosure)
        
        XCTAssertEqual("GET", spy!.lastRequest!.httpMethod!)
        XCTAssertTrue(spy!.wasDataTaskWithRequestCalled)
        XCTAssertTrue(spy!.dataTask.resumeWasCalled)
    }
    
    func testGetRequest_FakeDataSession_VerifyVariablesFirstTest()
    {
        // Arrange
        let expectedURL = URL(string: "FirstTest")!
        
        // Act
        // Assert
        var didCallClosure = false
        SUT!.getRequest(expectedURL) { parSON, responseString, error in
            
            didCallClosure = true
            XCTAssertEqual(expectedURL, self.spy!.lastRequest!.url)
        }
        
        XCTAssertTrue(didCallClosure)
    }
    
    func testGetRequest_FakeDataSession_VerifyVariablesSecondTest()
    {
        // Arrange
        let expectedURL = URL(string: "SecondTest")!
        
        // Act
        // Assert
        var didCallClosure = false
        SUT!.getRequest(expectedURL) { parSON, responseString, error in
            
            didCallClosure = true
            XCTAssertEqual(expectedURL, self.spy!.lastRequest!.url)
        }
        
        XCTAssertTrue(didCallClosure)
    }
    
    func testGetRequest_JSONHandlerFake_jsonObjectWasCalled()
    {
        // Arrange
        let spy = JSONHandlerFake.self
        let stub = URLSessionFake(dataToReturn: nil)
        SUT = RestAPI(urlSession: stub, jsonHandler: spy)
        
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        
        // Act
        SUT!.getRequest(expectedURL) { (parson, responseString, error) in
            XCTAssertTrue(spy.wasJSonObjectCalled)
        }
    }
    
    func testGetRequest_URLSessionFakeDictionaryData_VerifyDataFromDataTaskIsFirstTest()
    {
        // Arrange
        let expectedData = try? JSONSerialization.data(withJSONObject: ["Test": "1"], options: .prettyPrinted)
        
        guard expectedData != nil else {XCTFail(); return;}
        
        spy = URLSessionFake(dataToReturn: [expectedData!])
        SUT = RestAPI(urlSession: spy!, jsonHandler:JSONHandlerFake.self)
        
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        
        // Act
        
        SUT!.getRequest(expectedURL) { (parson, responseString, error) in
            XCTAssertNotNil(parson)
            XCTAssertEqual(expectedData!, JSONHandlerFake.lastData!)
            XCTAssertEqual("1", try? parson!.value(forKeyPath: "Test") as String)
            XCTAssertEqual(String(data: self.spy!.testData![0], encoding: String.Encoding.utf8), responseString!)
        }
    }
    
    func testGetRequest_URLSessionFakeDictionaryData_VerifyDataFromDataTaskIsSecondTest()
    {
        // Arrange
        let expectedData = try? JSONSerialization.data(withJSONObject: ["TestTwo": "2"], options: .prettyPrinted)
        
        guard expectedData != nil else {XCTFail(); return;}
        
        spy = URLSessionFake(dataToReturn: [expectedData!])
        SUT = RestAPI(urlSession: spy!, jsonHandler:JSONHandlerFake.self)
        
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        
        // Act
        
        SUT!.getRequest(expectedURL) { (parson, responseString, error) in
            XCTAssertNotNil(parson)
            XCTAssertEqual(expectedData!, JSONHandlerFake.lastData!)
            XCTAssertEqual("2", try? parson!.value(forKeyPath: "TestTwo") as String)
            XCTAssertEqual(String(data: self.spy!.testData![0], encoding: String.Encoding.utf8), responseString!)
        }
    }
    
    func testGetRequest_URLSessionFakeArrayData_VerifyDataFromDataTaskIsFirstTest()
    {
        // Arrange
        let expectedData = try? JSONSerialization.data(withJSONObject: ["first", "test", "1"], options: .prettyPrinted)
        
        guard expectedData != nil else {XCTFail(); return;}
        
        spy = URLSessionFake(dataToReturn: [expectedData!])
        SUT = RestAPI(urlSession: spy!, jsonHandler:JSONHandlerFake.self)
        
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        
        // Act
        
        SUT!.getRequest(expectedURL) { (parson, responseString, error) in
            XCTAssertNotNil(parson)
            XCTAssertEqual(expectedData!, JSONHandlerFake.lastData!)
            XCTAssertEqual("first", try? parson!.value(forKeyPath: "[0]") as String)
            XCTAssertEqual("test", try? parson!.value(forKeyPath: "[1]") as String)
            XCTAssertEqual("1", try? parson!.value(forKeyPath: "[2]") as String)
            XCTAssertEqual(String(data: self.spy!.testData![0], encoding: String.Encoding.utf8), responseString!)
        }
    }
    
    func testGetRequest_URLSessionFakeArrayData_VerifyDataFromDataTaskIsSecondTest()
    {
        // Arrange
        let expectedData = try? JSONSerialization.data(withJSONObject: ["second", "test", "2"], options: .prettyPrinted)
        
        guard expectedData != nil else {XCTFail(); return;}
        
        spy = URLSessionFake(dataToReturn: [expectedData!])
        SUT = RestAPI(urlSession: spy!, jsonHandler:JSONHandlerFake.self)
        
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        
        // Act
        
        SUT!.getRequest(expectedURL) { (parson, responseString, error) in
            XCTAssertNotNil(parson)
            XCTAssertEqual(expectedData!, JSONHandlerFake.lastData!)
            XCTAssertEqual("second", try? parson!.value(forKeyPath: "[0]") as String)
            XCTAssertEqual("test", try? parson!.value(forKeyPath: "[1]") as String)
            XCTAssertEqual("2", try? parson!.value(forKeyPath: "[2]") as String)
            XCTAssertEqual(String(data: self.spy!.testData![0], encoding: String.Encoding.utf8), responseString!)
        }
    }
    
    func testGetRequest_URLSessionFakeTestErrorTest1_errorIsTest1()
    {
        // Arrange
        spy!.testError = URLSessionErrorFake.first
        spy!.testData = [try! JSONSerialization.data(withJSONObject: ["Test": "1"], options: .prettyPrinted)]
        
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        
        // Act
        
        SUT?.getRequest(expectedURL, onCompletion: { (parson, responseString, error) in
            XCTAssertNil(parson)
            XCTAssertEqual(String(data: self.spy!.testData![0], encoding: String.Encoding.utf8), responseString!)
            XCTAssertEqual(URLSessionErrorFake.first.rawValue, (error as! URLSessionErrorFake).rawValue)
        })
    
    }
    
    func testGetRequest_URLSessionFakeTestErrorTestTwo2_errorIsTestTwo2()
    {
        // Arrange
        spy!.testError = URLSessionErrorFake.second
        spy!.testData = [try! JSONSerialization.data(withJSONObject: ["TestTwo": "2"], options: .prettyPrinted)]
        
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        
        // Act
        SUT?.getRequest(expectedURL, onCompletion: { (parson, responseString, error) in
            XCTAssertNil(parson)
            XCTAssertEqual(String(data: self.spy!.testData![0], encoding: String.Encoding.utf8), responseString!)
            XCTAssertEqual(URLSessionErrorFake.second.rawValue, (error as! URLSessionErrorFake).rawValue)
        })
    }
    
    func testGetRequest_requestHandlerSpy_VerifyRequestHandler()
    {
        // Arrange
        let requestStatusHandlerFake = RequestStatusHandlerFake()
        SUT = RestAPI(urlSession: spy!, jsonHandler: JSONHandlerFake.self, requestStatusHandler: requestStatusHandlerFake)
        spy!.testURLResponse = HTTPURLResponse.init(url: URL.temporaryURL(forFilename: ""), statusCode: RestAPIResponseCode.unauthorized.rawValue, httpVersion: nil, headerFields: nil)
        
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        
        // Act
        
        SUT!.getRequest(expectedURL) { (parson, responseString, error) in
            XCTAssertNil(parson)
            XCTAssertTrue(requestStatusHandlerFake.wasSuccessfulResponseCalled)
            XCTAssertTrue(requestStatusHandlerFake.wasReqestStatusCalled)
        }
    }
    
    //MARK: Delete Tests
    
    func testDeleteRequest_FakeDataSession_VerifyConstantsAndMethodCalls()
    {
        // Arrange
        let expectedURL = URL.temporaryURL(forFilename: "")
        spy?.testURLResponse = HTTPURLResponse.init(url: expectedURL, statusCode: RestAPIResponseCode.deleteSuccessful.rawValue, httpVersion: nil, headerFields: nil)
        
        // Act
        // Assert
        var didCallClosure = false
        
        SUT!.deleteRequest(expectedURL, field: "a", fieldValue: "a") { (parSON, responseString, error) in
            didCallClosure = true
        }
        
        XCTAssertTrue(didCallClosure)
        
        XCTAssertEqual("DELETE", spy!.lastRequest!.httpMethod!)
        XCTAssertTrue(spy!.wasDataTaskWithRequestCalled)
        XCTAssertTrue(spy!.dataTask.resumeWasCalled)
    }
    
    func testDeleteRequest_FakeDataSession_VerifyVariablesFirstTest()
    {
        // Arrange
        var expectedURL = URL(string: "FirstTest")!
        let expectedField = "testFieldOne"
        let expectedValue = "testValueOne"
        spy?.testURLResponse = HTTPURLResponse.init(url: expectedURL, statusCode: RestAPIResponseCode.deleteSuccessful.rawValue, httpVersion: nil, headerFields: nil)
        
        // Act
        // Assert
        var didCallClosure = false
        SUT!.deleteRequest(expectedURL, field: expectedField, fieldValue: expectedValue) { (parSON, responseString, error) in
            didCallClosure = true
            expectedURL.appendPathComponent("/\(expectedField)/\(expectedValue)")
            
            XCTAssertEqual(expectedURL, self.spy!.lastRequest!.url)
        }
       
        XCTAssertTrue(didCallClosure)
    }

    func testDeleteRequest_FakeDataSession_VerifyVariablesSecondTest()
    {
        // Arrange
        var expectedURL = URL(string: "SecondTest")!
        let expectedField = "testFieldTwo"
        let expectedValue = "testValueTwo"
        spy?.testURLResponse = HTTPURLResponse.init(url: expectedURL, statusCode: RestAPIResponseCode.deleteSuccessful.rawValue, httpVersion: nil, headerFields: nil)
        
        // Act
        // Assert
        var didCallClosure = false
        SUT!.deleteRequest(expectedURL, field: expectedField, fieldValue: expectedValue) { (parSON, responseString, error) in
            didCallClosure = true
            expectedURL.appendPathComponent("/\(expectedField)/\(expectedValue)")
            XCTAssertEqual(expectedURL, self.spy!.lastRequest!.url)
        }
        
        XCTAssertTrue(didCallClosure)
    }
 
    func testDeleteRequest_URLSessionFakeDictionaryData_VerifyDataFromDataTaskIsFirstTest()
    {
        // Arrange
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        
        spy?.testURLResponse = HTTPURLResponse.init(url: expectedURL, statusCode: RestAPIResponseCode.deleteSuccessful.rawValue, httpVersion: nil, headerFields: nil)
        SUT = RestAPI(urlSession: spy!, jsonHandler:JSONHandlerFake.self)
        
        // Act
        SUT?.deleteRequest(expectedURL, field: "a", fieldValue: "b", onCompletion: { (parSON, responseString, error) in
            XCTAssertNil(parSON)
            XCTAssertNil(error)
            XCTAssertEqual("204 Delete Successful", responseString!)

        })
    }
    
    func testDeleteRequest_URLSessionFake404_VerifyDataFromDataTaskIsSecondTest()
    {
        // Arrange
        let expectedURL = URL.temporaryURL(forFilename: "Test")
        
        spy?.testURLResponse = HTTPURLResponse.init(url: expectedURL, statusCode: RestAPIResponseCode.notFound.rawValue, httpVersion: nil, headerFields: nil)
        spy?.testData = [Data()]
        SUT = RestAPI(urlSession: spy!, jsonHandler:JSONHandlerFake.self)
        
        // Act
        var didCallClosure = false
        
        SUT?.deleteRequest(expectedURL, field: "a", fieldValue: "b", onCompletion: { (parSON, responseString, error) in
            didCallClosure = true
            XCTAssertNil(parSON)
            XCTAssertEqual(RestAPIResponseCode.notFound.rawValue, (error as! RestAPIResponseCode).rawValue)
        })
        
        XCTAssertTrue(didCallClosure)
    }
}
