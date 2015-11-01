//
//  Service.swift
//  iPromise
//
//  Created by jzaczek on 27.10.2015.
//  Copyright © 2015 jzaczek. All rights reserved.
//

import Foundation


/**
**TODO**: add a handle to provide a class for response objects or a handle to 
provide parsing logic

Represents a REST service. Allows for CRUD operations:

- **Create**: creates a single resource
- **Retrieve**: retrieve resources with specified id, filtered by parameters or
    all at uri of this ```Service```
- **Update**: updates a single resource
- **Destroy**: deletes a single resource

All requests are created using configuration from ServiceRealm for this Service. This includes
HTTP headers and HTTP methods for each of CRUD methods. ```NSData``` parameters are put into the
HTTP body of the request.

For more information about how to configure outgoing requests, read about ```ServiceRealm```
class.

**NOTE:** Any configuration can be overriden. Use ```override()``` method.

See:
- [REST](https://en.wikipedia.org/wiki/Representational_state_transfer)
- [CRUD](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete)
*/
public class Service {
    /**
    Simple enum for HTTP methods
    */
    public enum HTTPMethod: String {
        
        /// HTTP GET method. HTTPMethod.rawValue == "GET"
        ///
        /// See [GET at w3.org](http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html#sec9.3)
        case GET = "GET"
        
        /// HTTP POST method. HTTPMethod.rawValue == "POST"
        ///
        /// See [POST at w3.org](http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html#sec9.5)
        case POST = "POST"
        
        /// HTTP PUT method. HTTPMethod.rawValue == "PUT"
        ///
        /// See [PUT at w3.org](http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html#sec9.6)
        case PUT = "PUT"
        
        /// HTTP DELETE method. HTTPMethod.rawValue == "DELETE"
        ///
        /// See [DELETE at w3.org](http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html#sec9.7)
        case DELETE = "DELETE"
        
        /// HTTP PATCH method. HTTPMethod.rawValue == "PATCH"
        ///
        /// See [PATCH at IETF](https://tools.ietf.org/html/rfc5789) - RFC5789
        case PATCH = "PATCH"
    }
    
    /**
    Simple enum for CRUD methods
    
    REST APIs should conform to [these guidelines](http://www.restapitutorial.com/lessons/httpmethods.html)
    by default
    */
    public enum CRUDMethod: String {
        /// CRUD CREATE method. CRUDMethod.rawValue == "CREATE".
        /// This method creates new resources. APIs should return an URI for newly created resource
        case CREATE = "CREATE"
        
        /// CRUD RETRIEVE method. CRUDMethod.rawValue == "RETRIEVE".
        /// This method retrieves resources from the API.
        case RETRIEVE = "RETRIEVE"
        
        /// CRUD UPDATE method. CRUDMethod.rawValue == "UPDATE".
        /// This method updates a resource at a specific URI.
        case UPDATE = "UPDATE"
        
        /// CRUD DESTROY method. CRUDMethod.rawValue == "DESTROY".
        /// This method destroys a resource at a specific URI.
        case DESTROY = "DESTROY"
    }
    
    /**
    Type for errors thrown by this class's methods.
    */
    public enum ServiceError: ErrorType {
        
        /// Thrown when unable to parse the given base URL of the service. 
        /// String tuple contains the provided url
        case BaseUrlDirty(String)
        
        /// Thrown when unable to parse the given URI path. 
        /// String tuple contains the provided URI path.
        case UriPathDirty(String)
    }
    
    /// ```NSURLSession``` for this service.
    private var _session: NSURLSession!
    
    /// This service's URL
    private var _url: NSURL!
    
    /// Realm that this ```Service``` is registered in.
    private var _realm: ServiceRealm!
    
    /// Realm that overrides configuration only for this service
    private var _overridingRealm: ServiceRealm?
    
    /// Contains this ```Service```'s URL
    public var URL: NSURL {
        get {
            return _url
        }
    }
    
    /// Contains this services service realm. Read only. 
    ///
    /// If the realm behind this reference is modified, these changes will also
    /// influence other services of this Realm.
    public var Realm: ServiceRealm {
        get {
            return _realm
        }
    }
    
    /**
    Creates a new ```Service``` which is located at ```baseUrl``` at ```resourceUri``` path
    
    Example: 
    
        ```
        let baseUrl = "example.com"
        let servicePath = "api/v1/comments"
        do {
            let commentService = try Service(baseUrl: baseUrl, resourceUri: servicePath)
    
            // this retrieves resource at http://example.com/api/v1/comments/34/
            commentService.retrieve("34")   //.then(...)
        } 
        catch let error {
            // unable to create an URL
        }
        ```
    
    - parameter baseUrl: the URL of server which provides the service
    - parameter resourceUri: path to the service at that server
    
    - throws: ```Service.ServiceError``` when unable to parse provided args to a ```NSURL```
    */
    init(baseUrl: String, resourceUri: String) throws {
        _session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        
        let baseUrl = try Service.cleanBaseUrl(baseUrl)
        let resourceUri = try Service.cleanURIPath(resourceUri)
        
        _url = NSURL(string: "\(baseUrl)/\(resourceUri)")
        _realm = ServiceRealm.getDefault()
    }
    
    /**
    Creates a new ```Service``` located at provided NSURL
    
    Example:
    
        ```
        let url = NSURL(string: "http://example.com/api/v1/comments")!
        let commentService = Service(serviceUrl: url)
        
        // this retrieves resource at http://example.com/api/v1/comments/34/
        commentService.retrieve("34")   //.then(...)
        ```
    */
    init(serviceUrl: NSURL) {
        _session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        _url = serviceUrl
        _realm = ServiceRealm.getDefault()
    }
    
    /**
    Entry point for any overriding configuration. 
    
    Clones configuration from ```ServiceRealm``` of this ```Service``` and accepts overrides.
    
    Example:
    
    ```
    let service = Service(url: NSURL("some url")!)
    ServiceRealm
        .get("some realm")
        .register(service)
        //.addHeaders, .overrideCRUDMap
    
    //uses config from "some realm"
    service.retrieve("id")  //.then(...)
    
    //uses config cloned from "some realm" with overrides specified in the config closure
    service.override {
        realm in
        realm.cleanHeaders(["headerOne"])
    }.retrieve("id")        //.then(...)
    ```
    
    - parameter configuration: ```(ServiceRealm) -> Void closure. Provided realm accepts any overriding
        of configuration
    
    - returns: This ```Service```
    */
    public func override(configuration: (ServiceRealm) -> Void) -> Service {
        self._overridingRealm = self._realm.clone()
        
        configuration(self._overridingRealm!)
        
        return self
    }
    
    /**
    Creates a resource with provided ```NSData```.
    
    - parameter data: ```NSData``` to put into HTTP body of the request
    
    - returns: A ```Promise``` of the result. If promise is fulfilled this will be a tuple 
        containing data and response from the API. Otherwise it will contain the error
        returned by ```NSURLSession```.
    */
    public func create(data: NSData) -> Promise {
        return self.requestWithMethod(.CREATE, path: "", andData: data)
    }
    
    /**
    Retrieves a resource with located at provided path.
    
    - parameter path: URI of the resource relative to ```Service```'s URL
    
    - returns: A ```Promise``` of the result. If promise is fulfilled this will be a tuple
    containing data and response from the API. Otherwise it will contain the error
    returned by ```NSURLSession```.
    */
    public func retrieve(path: String) -> Promise {
        return self.requestWithMethod(.RETRIEVE, path: path)
    }
    
    /**
    Retrieves all resources from this service. Equivalent to calling ```retrieve("")``` (with 
    empty string as path).
    
    - returns: A ```Promise``` of the result. If promise is fulfilled this will be a tuple
    containing data and response from the API. Otherwise it will contain the error
    returned by ```NSURLSession```.
    */
    public func retrieve() -> Promise {
        return self.requestWithMethod(.RETRIEVE)
    }
    
    /**
    Retrieves a resource with provided filter dictionary.
    
    - parameter filter: A dictionary of parameters to be encoded in the request.
    
    - returns: A ```Promise``` of the result. If promise is fulfilled this will be a tuple
    containing data and response from the API. Otherwise it will contain the error
    returned by ```NSURLSession```.
    */
    public func retrieve(filter: [String: String]) -> Promise {
        return Promise.fulfill(NSHTTPURLResponse())
    }
    
    /**
    Updates a resource at a provided path with provided data.
    
    - parameter data: ```NSData``` to be put into HTTP body of the 
    - parameter path: URI of the resource relative to ```Service```'s URL
    
    - returns: A ```Promise``` of the result. If promise is fulfilled this will be a tuple
    containing data and response from the API. Otherwise it will contain the error
    returned by ```NSURLSession```.
    */
    public func update(path: String, data: NSData) -> Promise {
        return self.requestWithMethod(.UPDATE, path: path, andData: data)
    }
    
    /**
    Deletes a resource at a provided path.
    
    - parameter path: URI of the resource relative to ```Service```'s URL
    
    - returns: A ```Promise``` of the result. If promise is fulfilled this will be a tuple
    containing data and response from the API. Otherwise it will contain the error
    returned by ```NSURLSession```.
    */
    public func destroy(path: String) -> Promise {
        return self.requestWithMethod(.DESTROY, path: path)
    }
    
    /**
    Registers this ```Service``` in provided realm to use its request configuration.
    
    - parameter realm: A ```ServiceRealm``` with shared configuration. 
    */
    public func registerForRealm(realm: ServiceRealm) {
        self._realm = realm
    }
    
    
    /**
    Creates a NSURLRequest and initiates a data task which will supply the result. 
    
    Configuration is injected from ```ServiceRealm```
    
    - parameter method: CRUD method of this request - used to map to appropriate HTTP method
    - parameter path: URI path to append to URL of this ```Service```
    - parameter data: ```NSData``` to put into HTTP body of the request
    
    - returns: A ```Promise``` of the result.
    */
    private func requestWithMethod(method: CRUDMethod, path: String = "", andData data: NSData? = nil) -> Promise {
        do {
            let request = try self.getReuqestForMethod(method, andPath: path)
            request.HTTPBody = data
            
            return Promise {
                (fulfill, reject) in
                let dataTask = self._session.dataTaskWithRequest(request, completionHandler: {
                    (data, response, error) in
                    
                    guard error == nil && data != nil else {
                        reject(error)
                        return
                    }
                    
                    fulfill((data: data!, response: response!))
                    return
                    
                })
                
                dataTask.resume()
            }
        }
        catch let error {
            return Promise.reject(error)
        }
    }
    
    /**
    Creates a request and injects configuration from ```ServiceRealm```. 
    
    - parameter method: CRUD method of this request - used to map to appropriate HTTP method
    - parameter path: URI path to append to URL of this ```Service```
    
    - throws: ```Service.ServiceError.UriPathDirty(String)``` when unable to append path to
        URL of the ```Service```
    
    - returns: A NSMutableURLRequest with proper configuration.
    */
    private func getReuqestForMethod(method: CRUDMethod, andPath path: String = "") throws -> NSMutableURLRequest {
        let cleanPath = try Service.cleanURIPath(path)
        let url = self._url.URLByAppendingPathComponent(cleanPath)
        
        if self._overridingRealm != nil {
            let request = self._overridingRealm!.configuredRequestForMethod(method, andURL: url)
            self._overridingRealm = nil
            return request
        }
        
        return self._realm.configuredRequestForMethod(method, andURL: url)
    }
    
    /**
    A clean URL should look like this: **http://example.com**
    
    1. Attempt to remove trailing slash from the url
    2. Attempt to add http:// prefix
    3. Throw when everything fails
    
    - parameter baseUrl: URL to be cleaned
    
    - throws: ```ServiceError.BaseUrlDirty(String)``` when unable to parse the URL
    
    - returns: Cleaned URL
    */
    private class func cleanBaseUrl(baseUrl: String) throws -> String {
        var dirtyUrl = baseUrl
        
        if dirtyUrl.hasSuffix("/") {
            dirtyUrl = dirtyUrl.substringToIndex(dirtyUrl.endIndex.predecessor())
        }
        
        if !dirtyUrl.hasPrefix("http://") || !dirtyUrl.hasPrefix("https://") {
            dirtyUrl = "https://" + dirtyUrl
        }
        
        if NSURL(string: dirtyUrl) != nil {
            return dirtyUrl
        }
        
        throw ServiceError.BaseUrlDirty(baseUrl)
    }
    
    /**
    A clean path should look like this: **this/is/a/path**
    
    1. Attempt to append the path to example url with preceding / to see if NSURL parses it
    2. Throw
    
    - parameter path: URI path to be cleaned
    
    - throws: ```ServiceError.UriPathDirty(String)``` when unable to parse the URL
    
    - returns: Cleaned URI path
    */
    private class func cleanURIPath(path: String) throws -> String {
        let exampleUrl = "http://example.com"
        
        if NSURL(string: "\(exampleUrl)/\(path)/") != nil {
            return path
        }
        
        throw ServiceError.UriPathDirty(path)
    }
}