//
//  RestAPITests.swift
//  WhatTodo
//
//  Created by Ben Fowler on 15/12/2016.
//  Copyright © 2016 BF. All rights reserved.
//

import XCTest
@testable import WhatTodo

//MARK:Fake
class URLSessionFake: URLSessionProtocol
{
    private(set) var lastURL: URL?
    var testData: [Data]? {  didSet{ dataIterator = (testData?.makeIterator())! } }
    private var dataIterator: IndexingIterator<[Data]>?
    var testError: Error?
    let dataTask = FakeURLSessionDataTask()
    
    
    func dataTask(with url: URL, completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol {
        lastURL = url
        completionHandler(dataIterator?.next(), nil, testError)
        return dataTask
    }
    
    private(set) var wasDataTaskWithRequestCalled = false
    
    func dataTask(with request: URLRequest, completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol {
        self.wasDataTaskWithRequestCalled = true
        return dataTask
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
    
    func testPostRequest_spy_dataTaskResumeCalled()
    {
        // Arrange
        let spy = URLSessionFake()
        let SUT = RestAPI(urlSession: spy)
        
        // Act
        SUT.postRequest(id: "", title: "", description: "") { (parson, response, error) in
            
        }
    
        // Assert
        XCTAssertTrue(spy.wasDataTaskWithRequestCalled)
        XCTAssertTrue(spy.dataTask.resumeWasCalled)
    }
}
