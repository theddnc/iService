//
//  ConfigurationTests.swift
//  iService
//
//  Created by jzaczek on 20.12.2015.
//  Copyright © 2015 jzaczek. All rights reserved.
//

import XCTest
import Nocilla
import iPromise
@testable import iService

class ConfigurationTests: JZTestCase {

    let baseUrl = "https://mock.com"
    let resource = "resource"
    
    override func setUp() {
        super.setUp()
        ServiceRealm.get("test_realm")
    }
    
    override func tearDown() {
        ServiceRealm.destroy("test_realm")
        super.tearDown()
    }
    
    func testConfigureGlobalHTTPHeaders() {
        expect { testExpectation in
            stubRequest("GET", "\(self.baseUrl)/\(self.resource)/1?")
                .andReturn(200)
                .withBody("{\"key\":\"value\"}")
            
            let headers = [
                "Authorization" : "Silly 12345",
                "Content-Type": "application/json"
            ]
            
            ServiceRealm
                .get("test_realm")
                .addHeaders(headers)
            
            let service = try! Service(baseUrl: self.baseUrl, resourceUri: self.resource)
            service.registerForRealm(ServiceRealm.get("test_realm"))
            
            service
                .retrieve("1")
                .success { result in
                    XCTAssertEqual(result.request.allHTTPHeaderFields ?? [:], headers, "Headers are different!")
                    testExpectation.fulfill()
                }
        }
    }
    
    func testConfigureHeadersForRetrieveOnly() {
        expect { testExpectation in
            stubRequest("GET", "\(self.baseUrl)/\(self.resource)/1?")
                .andReturn(200)
                .withBody("{\"key\":\"value\"}")
            
            stubRequest("DELETE", "\(self.baseUrl)/\(self.resource)/1?")
                .andReturn(204)
            
            let headers = [
                "Authorization" : "Silly 12345",
                "Content-Type": "application/json"
            ]
            
            ServiceRealm
                .get("test_realm")
                .addHeaders(headers, specificForCRUDMethod: .RETRIEVE)
            
            let service = try! Service(baseUrl: self.baseUrl, resourceUri: self.resource)
            service.registerForRealm(ServiceRealm.get("test_realm"))
            
            service
                .retrieve("1")
                .then({ result -> Promise<ResponseBundle> in
                    XCTAssertEqual(result.request.allHTTPHeaderFields ?? [:], headers, "Headers are different!")
                
                    return service.destroy("1")
                }).then({ result in
                    XCTAssertEqual(result.request.allHTTPHeaderFields ?? [:], [:], "Headers are different!")
                    testExpectation.fulfill()
                })
        }
    }
    
    func testOverrideCrudMap() {
        expect { testExpectation in
            stubRequest("PUT", "\(self.baseUrl)/\(self.resource)/?")
                .andReturn(201)
                .withBody("{\"key\":\"value\"}")
            
            stubRequest("POST", "\(self.baseUrl)/\(self.resource)/1?")
                .andReturn(200)
                .withBody("{\"key\":\"value\"}")
            
            stubRequest("PATCH", "\(self.baseUrl)/\(self.resource)/1?")
                .andReturn(200)
                .withBody("{\"key\":\"value\"}")
            
            stubRequest("POST", "\(self.baseUrl)/\(self.resource)/1?")
                .andReturn(204)
                .withBody("")
            
            let service = try! Service(baseUrl: self.baseUrl, resourceUri: self.resource)
            
            ServiceRealm
                .get("test_realm")
                .overrideCrudMap([
                    .CREATE: .PUT,
                    .RETRIEVE: .POST,
                    .UPDATE: .PATCH,
                    .DESTROY: .POST
                ])
                .register(service)
            
            service.create(self.data("{}")).then({ result -> Promise<ResponseBundle> in
                XCTAssertEqual(result.request.HTTPMethod, Service.HTTPMethod.PUT.rawValue, ".CREATE: .PUT")
                return service.retrieve("1")
            }).then({ result -> Promise<ResponseBundle> in
                XCTAssertEqual(result.request.HTTPMethod, Service.HTTPMethod.POST.rawValue, ".RETRIEVE: .POST")
                return service.update("1", data: self.data("{}"))
            }).then({ result -> Promise<ResponseBundle> in
                XCTAssertEqual(result.request.HTTPMethod, Service.HTTPMethod.PATCH.rawValue, ".UPDATE: .PATCH")
                return service.destroy("1")
            }).then({ result in
                XCTAssertEqual(result.request.HTTPMethod, Service.HTTPMethod.POST.rawValue, ".DESTROY: .POST")
                testExpectation.fulfill()
            })
        }
    }
    
    func testAddHeadersCleanHeaders() {
        expect { testExpectation in
            stubRequest("GET", "\(self.baseUrl)/\(self.resource)/1?")
                .andReturn(201)
                .withBody("{\"key\":\"value\"}")
            
            let service = try! Service(baseUrl: self.baseUrl, resourceUri: self.resource)
            
            ServiceRealm
                .get("test_realm")
                .addHeader("Authorization", withValue: "Silly 123456")
                .register(service)
            
            service.retrieve("1").then({ result -> Service.ResponsePromise in
                XCTAssertEqual(result.request.allHTTPHeaderFields ?? [:], ["Authorization": "Silly 123456"], "Different headers")
                ServiceRealm
                    .get("test_realm")
                    .cleanHeaders(["Authorization"])
                return service.retrieve("1")
            }).then({ result in
                XCTAssertEqual(result.request.allHTTPHeaderFields ?? [:], [:], "Different headers")
                testExpectation.fulfill()
            })
        }
    }
    
    func testAddHeadersCleanHeadersForDestroy() {
        expect { testExpectation in
            stubRequest("DELETE", "\(self.baseUrl)/\(self.resource)/1?")
                .andReturn(204)
            stubRequest("GET", "\(self.baseUrl)/\(self.resource)/1?")
                .andReturn(200)
                .withBody("{}")
            
            let service = try! Service(baseUrl: self.baseUrl, resourceUri: self.resource)
            
            ServiceRealm
                .get("test_realm")
                .addHeader("Authorization", withValue: "Silly 123456", specificForCRUDMethod: .DESTROY)
                .register(service)
            
            service.destroy("1").then({ result -> Service.ResponsePromise in
                XCTAssertEqual(result.request.allHTTPHeaderFields ?? [:], ["Authorization": "Silly 123456"], "Different headers")
                return service.retrieve("1")
            }).then({ result -> Service.ResponsePromise in
                XCTAssertEqual(result.request.allHTTPHeaderFields ?? [:], [:], "Different headers")
                ServiceRealm
                    .get("test_realm")
                    .cleanHeaders(["Authorization"], forCRUDMethod: .DESTROY)
                return service.destroy("1")
            }).then({ result in
                XCTAssertEqual(result.request.allHTTPHeaderFields ?? [:], [:], "Different headers")
                testExpectation.fulfill()
            })
        }
    }
    
    func testOverrideCachePolicy() {
        expect { testExpectation in
            stubRequest("GET", "\(self.baseUrl)/\(self.resource)/1?")
                .andReturn(200)
                .withBody("{}")
            stubRequest("DELETE", "\(self.baseUrl)/\(self.resource)/1?")
                .andReturn(204)
            
            let service = Service(serviceUrl: NSURL(string: "https://mock.com/resource")!)
            
            ServiceRealm
                .get("test_realm")
                .overrideGlobalCachePolicy(.ReloadIgnoringCacheData)
                .overrideCachePolicy(.ReturnCacheDataElseLoad, forCrudMethod: .DESTROY)
            
            ServiceRealm.registerService(service, forRealmAtKey: "test_realm")
            
            service.retrieve("1").then({ result -> Service.ResponsePromise in
                XCTAssertEqual(result.request.cachePolicy, NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData, "Cache policy different")
                return service.destroy("1")
            }).then({ result in
                XCTAssertEqual(result.request.cachePolicy, NSURLRequestCachePolicy.ReturnCacheDataElseLoad, "Cache policy different")
                testExpectation.fulfill()
            })
        }
    }
    
    func testUrlCleaning() {
        do {
            try _ = Service(baseUrl: "www.mock.com/", resourceUri: "ąę")
        }
        catch Service.ServiceError.UriPathDirty(let path) {
            XCTAssertEqual(path, "ąę", "Expected to fail")
        }
        catch _ {
            
        }
        
        do {
            try _ = Service(baseUrl: "this is a regular string", resourceUri: "this is also a regular string")
        }
        catch Service.ServiceError.BaseUrlDirty(let baseUrl) {
            XCTAssertEqual("this is a regular string", baseUrl, "Expected to fail")
        }
        catch _ {
            
        }
    }
    
    func testGettersToHaveBetterCoverage() {
        let service = Service(serviceUrl: NSURL(string: "www.mock.com")!)
        
        XCTAssertEqual(service.URL, NSURL(string: "www.mock.com"), "URLs should be equal")
        
        service.registerForRealm(ServiceRealm.get("test_realm"))
        
        XCTAssertEqual(service.realm.id, ServiceRealm.get("test_realm").id, "Realms should be equal")
    }
}
