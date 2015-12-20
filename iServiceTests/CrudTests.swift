//
//  iServiceTests.swift
//  iServiceTests
//
//  Created by jzaczek on 19.12.2015.
//  Copyright © 2015 jzaczek. All rights reserved.
//

import XCTest
import Nocilla
import iPromise
@testable import iService

class CrudTests: JZTestCase {
    
    let baseUrl = "https://mock.com"
    let resource = "resource"
    
    func testRetrieveSingleItem() {
        expect { testExpectation in
            stubRequest("GET", "\(self.baseUrl)/\(self.resource)/1?")
                .andReturn(200)
                .withBody("{\"key\":\"value\"}")
            
            try! Service(baseUrl: self.baseUrl, resourceUri: self.resource)
                .retrieve("1")
                .success { result in
                    XCTAssertEqual(result.response?.statusCode, 200, "Status code different than 200")
                    XCTAssertEqual(self.str(result.data), "{\"key\":\"value\"}", "Different data")
                    XCTAssertEqual(result.error, nil, "Error is not nil")
                    testExpectation.fulfill()
                }
        }
    }
    
    func testRetrieveAllItems() {
        expect { testExpectation in
            stubRequest("GET", "\(self.baseUrl)/\(self.resource)/?")
                .andReturn(200)
                .withBody("[{\"key\":\"value\"}, {\"key\":\"value2\"}]")
            
            try! Service(baseUrl: self.baseUrl, resourceUri: self.resource)
                .retrieve()
                .success { result in
                    XCTAssertEqual(result.response?.statusCode, 200, "Status code different than 200")
                    XCTAssertEqual(self.str(result.data), "[{\"key\":\"value\"}, {\"key\":\"value2\"}]", "Different data")
                    XCTAssertEqual(result.error, nil, "Error is not nil")
                    testExpectation.fulfill()
            }
        }
    }
    
    func testRetrieveFilteredList() {
        expect { testExpectation in
            stubRequest("GET", "\(self.baseUrl)/\(self.resource)/?key=value2&")
                .andReturn(200)
                .withBody("[{\"key\":\"value2\"}]")

            try! Service(baseUrl: self.baseUrl, resourceUri: self.resource)
                .retrieve(["key": "value2"])
                .success { result in
                    XCTAssertEqual(result.response?.statusCode, 200, "Status code different than 200")
                    XCTAssertEqual(self.str(result.data), "[{\"key\":\"value2\"}]", "Different data")
                    XCTAssertEqual(result.error, nil, "Error is not nil")
                    testExpectation.fulfill()
            }
        }
    }
    
    func testRetrieveParseError() {
        expect { testExpectation in
            stubRequest("GET", "\(self.baseUrl)/\(self.resource)/1?")
                .andReturn(200)
                .withBody("{\"key\":\"value\"}")
            
            try! Service(baseUrl: self.baseUrl, resourceUri: self.resource)
                .retrieve("ąćęłńóśżź")
                .then({ result in
                    XCTFail("Expected success handler not to be called")
                    testExpectation.fulfill()
                }, onFailure:{ err in
                    guard let error = err as? Service.ServiceError else {
                        throw err
                    }
                    
                    switch error {
                    case .UriPathDirty(let path):
                        XCTAssertEqual(path, "ąćęłńóśżź", "Different paths")
                        testExpectation.fulfill()
                    default:
                        break
                    }
                })
        }
    }
    
    func testDestroy() {
        expect { testExpectation in
            stubRequest("DELETE", "\(self.baseUrl)/\(self.resource)/1?")
                .andReturn(204)
            
            try! Service(baseUrl: self.baseUrl, resourceUri: self.resource)
                .destroy("1")
                .success { result in
                    XCTAssertEqual(result.response?.statusCode, 204, "Status code different than 204")
                    XCTAssertEqual(self.str(result.data), "", "Data is not empty")
                    XCTAssertEqual(result.error, nil, "Error is not nil")
                    testExpectation.fulfill()
            }
        }
    }
    
    func testCreate() {
        expect { testExpectation in
            stubRequest("POST", "\(self.baseUrl)/\(self.resource)/?")
                .andReturn(201)
                .withBody("{\"key\":\"value3\"}")
            
            try! Service(baseUrl: self.baseUrl, resourceUri: self.resource)
                .create(self.data("{\"key\":\"value3\"}"))
                .success { result in
                    XCTAssertEqual(result.response?.statusCode, 201, "Status code different than 201")
                    XCTAssertEqual(self.str(result.data), "{\"key\":\"value3\"}", "Data is empty")
                    XCTAssertEqual(result.error, nil, "Error is not nil")
                    testExpectation.fulfill()
            }
        }
    }
    
    func testUpdate() {
        expect { testExpectation in
            stubRequest("PUT", "\(self.baseUrl)/\(self.resource)/3?")
                .andReturn(200)
                .withBody("{\"key\":\"value4\"}")
            
            try! Service(baseUrl: self.baseUrl, resourceUri: self.resource)
                .update("3", data: self.data("{\"key\":\"value4\"}"))
                .success { result in
                    XCTAssertEqual(result.response?.statusCode, 200, "Status code different than 200")
                    XCTAssertEqual(self.str(result.data), "{\"key\":\"value4\"}", "Data is empty")
                    XCTAssertEqual(result.error, nil, "Error is not nil")
                    testExpectation.fulfill()
            }
        }
    }
    
    func testPartialUpdateWithPATCH() {
        expect { testExpectation in
            stubRequest("PATCH", "\(self.baseUrl)/\(self.resource)/3?")
                .andReturn(200)
                .withBody("{\"key\":\"value4\"}")
            
            try! Service(baseUrl: self.baseUrl, resourceUri: self.resource)
                .override { config in
                    config.overrideCrudMethod(.UPDATE, withHTTPMethod: .PATCH)
                }
                .update("3", data: self.data("{\"key\":\"value4\", \"key2\": \"value69\"}"))
                .success { result in
                    XCTAssertEqual(result.response?.statusCode, 200, "Status code different than 200")
                    XCTAssertEqual(self.str(result.data), "{\"key\":\"value4\"}", "Data is empty")
                    XCTAssertEqual(result.error, nil, "Error is not nil")
                    testExpectation.fulfill()
            }
        }
    }
}
