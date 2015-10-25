//
//  Resource.swift
//  iPromise
//
//  Created by jzaczek on 27.10.2015.
//  Copyright © 2015 jzaczek. All rights reserved.
//

import Foundation


/**
Represents a REST resource. Allows for CRUD operations:
- **Create**: creates a single resource
- **Retrieve**: retrieve resources with specified id, filtered by parameters or
    all at uri of this ```Resource```
- **Update**: updates a single resource
- **Delete**: deletes a single resource

See:
- [REST](https://en.wikipedia.org/wiki/Representational_state_transfer)
- [CRUD](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete)
*/
public class Resource {
    public enum HTTPMethod: String {
        case GET = "GET"
        case POST = "POST"
        case PUT = "PUT"
        case DELETE = "DELETE"
        case PATCH = "PATCH"
    }
    
    public enum CRUDMethod: String {
        case CREATE = "CREATE"
        case RETRIEVE = "RETRIEVE"
        case UPDATE = "UPDATE"
        case DESTROY = "DESTROY"
    }
    
    private var _session: NSURLSession
    private var _baseUrl: String
    private var _resourceUri: String
    private var _realm: ResourceRealm
    
    //consider optional initialization - if unable to create nsurl from base or base+resource
    //return nil
    //or throw
    init(baseUrl: String, resourceUri: String) {
        _session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        _baseUrl = baseUrl              // this needs to be idiot-proof
        _resourceUri = resourceUri      // this needs to be idiot-proof
        _realm = ResourceRealm.getDefault()
    }
    
    /// Creates a single resource
    public func create(data: NSData) -> Promise {
        let url = NSURL(string: "\(_baseUrl)\(_resourceUri)")!
        let request = self.getReuqestForURL(url, andMethod: .CREATE)
        request.HTTPBody = data
        
        return self.promiseForRequest(request)
    }
    
    /// Retrieves a single resource with identifier
    /// todo: path has to be idiot-proof
    /// throws?
    public func retrieve(path: String) -> Promise {
        let url = NSURL(string: "\(_baseUrl)\(_resourceUri)\(path)")!
        let request = self.getReuqestForURL(url, andMethod: .RETRIEVE)
        
        return self.promiseForRequest(request)
    }
    
    /// Retrieves all resources from uri
    public func retrieve() -> Promise {
        let url = NSURL(string: "\(_baseUrl)\(_resourceUri))")!
        let request = self.getReuqestForURL(url, andMethod: .RETRIEVE)
        
        return self.promiseForRequest(request)
    }
    
    /// Retrieves all resources from uri which conform to a filter
    public func retrieve(filter: [String: String]) -> Promise {
        return Promise.fulfill(NSHTTPURLResponse())
    }
    
    /// Updates a single resource
    public func update(data: NSData, identifier: String) -> Promise {
        return Promise.fulfill(NSHTTPURLResponse())
    }
    
    /// Deletes a single resource
    public func delete(identifier: String) -> Promise {
        return Promise.fulfill(NSHTTPURLResponse())
    }
    
    public func registerForRealm(realm: ResourceRealm) {
        self._realm = realm
    }
    
    private func getReuqestForURL(url: NSURL, andMethod method: CRUDMethod) -> NSMutableURLRequest {
        let cachePolicy = self.cachePolicyForMethod(method)
        let request = NSMutableURLRequest(URL: url, cachePolicy: cachePolicy, timeoutInterval: 60.0)
        
        for (key, value) in self._realm.HTTPHeaders {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        if self._realm.CRUDSpecificHTTPHeaders.keys.contains(method) {
            for (key, value) in self._realm.CRUDSpecificHTTPHeaders[method]! {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        if self._realm.CRUDMethodMap.keys.contains(method) {
            request.HTTPMethod = self._realm.CRUDMethodMap[method]!.rawValue
        }
        else {
            request.HTTPMethod = ResourceRealm.getDefaultCrudMap()[method]!.rawValue
        }
        
        return request
    }
    
    private func cachePolicyForMethod(method: CRUDMethod) -> NSURLRequestCachePolicy {
        if self._realm.CRUDSpecificCachePolicies.keys.contains(method) {
            return self._realm.CRUDSpecificCachePolicies[method]!
        }
        
        return self._realm.CachePolicy
    }
    
    private func promiseForRequest(request: NSURLRequest) -> Promise {
        return Promise {
            (fulfill, reject) in
            let dataTask = self._session.dataTaskWithRequest(request, completionHandler: {
                (data, response, error) in
                if error == nil && data != nil {
                    fulfill((data: data!, response: response!))
                    return
                }
                reject(error)
            })
            
            dataTask.resume()
        }
    }
}