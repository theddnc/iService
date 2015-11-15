//
//  ServiceRealm.swift
//  iPromise
//
//  Created by jzaczek on 30.10.2015.
//  Copyright © 2015 jzaczek. All rights reserved.
//

import Foundation

/**
**TODO:** add possibility to list all services in this realm - for debugging (?)

A ServiceRealm is an entry point for shared configuration of Services.

After creating and configuring a realm, Services can be registered for it, and configuration
provided will be used for every request. 

For example, if an API protects some of its services with APIKey authentication 
and some are publicly available, two realms can be created:
 - first for publicly available services, e.g. ```ServiceRealm.getDefault()```
 - second one for services hidden behind APIKey, with appropriate headers set
    ```
    ServiceRealm.get("www.example.com/hidden").addHeaders(
        ["Authentication": "ApiKey (...)"]
    )
    ```

This class supports chained calls. All overriding functions return ServiceRealms.

Supported configuration options:
 - CRUD method - HTTP method map - for APIs that do not conform to the default
    (or the most sane) CRUD - HTTP mapping
 - HTTP headers
 - CRUD method specific HTTP headers - for APIs that use some weird and 'legacy' 
    interfaces which make use of HTTP headers
*/
public class ServiceRealm {
    /// Type representing a map of CRUD methods and their corresponding HTTP methods
    public typealias CRUDMap = [Service.CRUDMethod: Service.HTTPMethod]
    
    /// Type representing a dictionary of HTTP headers
    public typealias HTTPHeaderDictionary = [String: String]
    
    /**
    Contains default CRUD method - HTTP method map:

    ```
    [
        .CREATE:    .POST,
        .RETRIEVE:  .GET,
        .UPDATE:    .PUT,
        .DESTROY:   .DELETE,
    ]
    ```
    */
    static public let defaultCRUDMap: CRUDMap = [
        .CREATE:    .POST,
        .RETRIEVE:  .GET,
        .UPDATE:    .PUT,
        .DESTROY:   .DELETE
    ]
    
    /**
    Contains default CRUD specific headers dictionary:
    
    ```
    [
        .CREATE:    [:],
        .RETRIEVE:  [:],
        .UPDATE:    [:],
        .DESTROY:   [:]
    ]
    ```
    */
    static public let defaultCRUDSpecificHeaders: [Service.CRUDMethod: HTTPHeaderDictionary] = [
        .CREATE:    [:],
        .RETRIEVE:  [:],
        .UPDATE:    [:],
        .DESTROY:   [:]
    ]
    
    /// Array of user defined ServiceRealms
    static private var realms: [String: ServiceRealm] = [:]
    
    /// Default realm with default configuration. All services use this configuration, unless
    /// registered for a different realm.
    static private var defaultRealm: ServiceRealm = ServiceRealm()
    
    /// Dictionary of HTTP headers to add to every request coming out of this realm
    private var _headers: HTTPHeaderDictionary
    
    /// Global cache policy for this realm
    private var _cachePolicy: NSURLRequestCachePolicy
    
    /// Map of CRUD methods and their corresponding HTTP headers
    private var _crudSpecificHeaders: [Service.CRUDMethod: HTTPHeaderDictionary]
    
    /// Map of CRUD methods and their corresponding cache policies
    private var _crudSpecificCachePolicies: [Service.CRUDMethod: NSURLRequestCachePolicy]
    
    /// CRUD method - HTTP method map
    private var _crudMethodMap: CRUDMap
    
    /// Identifier for this realm
    private var _id: String = NSUUID().UUIDString
    
    /// User-defined key for this realm
    private var _key: String = ""
    
    /// Contains unique id for this realm, read only
    /// **TODO:** is this necessary?
    public var Identifier: String {
        get {
            return "KEY: \(_key), ID: \(_id)\n"
        }
    }
    
    /// Contains HTTPHeaders for this realm, read only
    public var HTTPHeaders: HTTPHeaderDictionary {
        get {
            return _headers
        }
    }
    
    /// Contains map of CRUD methods and their corresponding HTTP headers, read only
    public var CRUDSpecificHTTPHeaders: [Service.CRUDMethod: HTTPHeaderDictionary] {
        get {
            return _crudSpecificHeaders
        }
    }
    
    /// Contains CRUD method - HTTP method map, read only
    public var CRUDMethodMap: CRUDMap {
        get {
            return _crudMethodMap
        }
    }
    
    /// Contains global cache policy
    public var CachePolicy: NSURLRequestCachePolicy {
        get {
            return _cachePolicy
        }
    }
    
    ///Contains map of CRUD methods and their corresponding cache policies
    public var CRUDSpecificCachePolicies: [Service.CRUDMethod: NSURLRequestCachePolicy] {
        get {
            return _crudSpecificCachePolicies
        }
    }
    
    /// Creates a default realm
    private init() {
        _headers = [:]
        _crudSpecificHeaders = ServiceRealm.defaultCRUDSpecificHeaders
        _crudMethodMap = ServiceRealm.defaultCRUDMap
        _cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
        _crudSpecificCachePolicies = [:]
    }
    
    /**
    Creates a fully configured request for a given CRUD method and URL
    
    Injects headers, cache policy and uses apropriate HTTP method. 
    
    - parameter method: ```Service.CRUDMethod```
    - parameter url: ```NSURL``` of the request
    
    - returns: ```NSMutableURLRequest```
    */
    public func configuredRequestForMethod(method: Service.CRUDMethod, andURL url: NSURL) -> NSMutableURLRequest {
        let cachePolicy = self.cachePolicyForMethod(method)
        let request = NSMutableURLRequest(URL: url, cachePolicy: cachePolicy, timeoutInterval: 60.0)
        
        // set all http headers for this crud method to this request
        request.allHTTPHeaderFields = self.allHTTPHeadersForMethod(method)
        
        // use correct http method for this request
        request.HTTPMethod = (self.CRUDMethodMap[method] ?? ServiceRealm.defaultCRUDMap[method]!).rawValue
        
        return request
    }
    
    /**
    Overrides default CRUD method - HTTP method map with passed argument
    
     - parameter map: A dictionary of type ```[Service.CRUDMethod: Service.HTTPMethod]```
    
     - returns: This ```ServiceRealm```
    */
    public func overrideCrudMap(map: CRUDMap) -> ServiceRealm {
        self._crudMethodMap = map
        
        return self
    }
    
    /**
    Overrides CRUD method with HTTP method passed as the argument.
    
     - parameter method: CRUD method to override. See ```Service.CRUDMethod```
     - parameter httpMethod: HTTP method to override. See ```Service.HTTPMethod```
    
     - returns: This ```ServiceRealm```
    */
    public func overrideCrudMethod(method: Service.CRUDMethod, withHTTPMethod httpMethod: Service.HTTPMethod) -> ServiceRealm {
        self._crudMethodMap.updateValue(httpMethod, forKey: method)
        
        return self
    }
    
    /**
    Adds a single header value to HTTP header dictionary
    
     - parameter header: HTTP header field name
     - parameter value: Value of the HTTP header field
     
     - returns: This ```ServiceRealm```
    */
    public func addHeader(header: String, withValue value: String) -> ServiceRealm {
        self._headers.updateValue(value, forKey: header)
        
        return self
    }
    
    /**
    Adds multiple headers to HTTP header dictionary. If a header from ```headers``` parameter is already
    defined, its value is set to a corresponding value from ```headers```.
    
     - parameter headers: Dictionary of headers to be merged with internal HTTP header dictionary
    
     - returns: This ```ServiceRealm```
    */
    public func addHeaders(headers: HTTPHeaderDictionary) -> ServiceRealm {
        for (key, value) in headers {
            self._headers.updateValue(value, forKey: key)
        }
        
        return self
    }
    
    /**
    Adds a single header value to HTTP header dictionary for a specific CRUD method
    
     - parameter header: HTTP header field name
     - parameter value: Value of the HTTP header field
     - parameter method: See ```Service.CRUDMethod```
    
     - returns: This ```ServiceRealm```
    */
    public func addHeader(header: String, withValue value: String, specificForCRUDMethod crudMethod: Service.CRUDMethod) -> ServiceRealm {
        self._crudSpecificHeaders[crudMethod]?.updateValue(value, forKey: header)
        
        return self
    }
    
    /**
    Adds multiple headers to HTTP header dictionary for a specific CRUD method. If a header from ```headers``` 
    parameter is already defined, its value is set to a corresponding value from ```headers```.
    
     - parameter headers: Dictionary of headers to be merged with internal HTTP header dictionary
     - parameter method: See ```Service.CRUDMethod```
    
     - returns: This ```ServiceRealm```
    */
    public func addHeaders(headers: HTTPHeaderDictionary, specificForCRUDMethod crudMethod: Service.CRUDMethod) -> ServiceRealm {
        for (key, value) in headers {
            self._crudSpecificHeaders[crudMethod]?.updateValue(value, forKey: key)
        }
        
        return self
    }
    
    /**
    Removes headers with their values from the configuration.
    
    - parameter headers: An ```Array``` of ```String``` keys representing headers to be removed.
    
    - returns: This ```ServiceRealm```
    */
    public func cleanHeaders(headers: [String]) -> ServiceRealm {
        for header in headers {
            self._headers.removeValueForKey(header)
        }
        
        return self
    }
    
    /**
    Removes headers with their values from the configuration for a specified CRUD method.
    
    - parameter headers: An ```Array``` of ```String``` keys representing headers to be removed.
    - parameter method: ```Service.CRUDMethod```
    
    - returns: This ```ServiceRealm```
    */
    public func cleanHeaders(headers: [String], forCRUDMethod method: Service.CRUDMethod) -> ServiceRealm {
        for header in headers {
            self._crudSpecificHeaders[method]?.removeValueForKey(header)
        }
        
        return self
    }
    
    /**
    Overrides global cache policy. Policies for CRUD methods can be overriden separately
    and have higher priority.
    
     - parameter cachePolicy: ```NSURLRequestCachePolicy``` to be set as default
    
     - returns: This ```ServiceRealm```
    */
    public func overrideGlobalCachePolicy(cachePolicy: NSURLRequestCachePolicy) -> ServiceRealm {
        self._cachePolicy = cachePolicy
        
        return self
    }
    
    /**
    Overrides CRUD method specific cache policy. This policy has a higher priority 
    than the global policy.
    
    - parameter cachePolicy: ```NSURLRequestCachePolicy``` to be set for this method
    - parameter method: See: ```Service.CRUDMethod```
    
    - returns: This ```ServiceRealm```
    */
    public func overrideCachePolicy(cachePolicy: NSURLRequestCachePolicy, forCrudMethod method: Service.CRUDMethod) -> ServiceRealm {
        self._crudSpecificCachePolicies.updateValue(cachePolicy, forKey: method)
        
        return self
    }
    
    /**
    Register a service in this ```ServiceRealm```. 
    
    Registering in a service realm provides an entry point for configuration.
    
    - parameter service: ```Service``` to be registered for this configuration
    
    - returns: This ```ServiceRealm```
    */
    public func register(service: Service) -> ServiceRealm {
        service.registerForRealm(self)
        
        return self
    }
    
    /**
    Returns a cache policy for requested CRUD method. If none is specified, returns
    the global cache policy.
    
    - parameter method: ```Service.CRUDMethod```
    
    - returns: A ```NSURLRequestCachePolicy``` for specified method.
    */
    public func cachePolicyForMethod(method: Service.CRUDMethod) -> NSURLRequestCachePolicy {
        if self.CRUDSpecificCachePolicies.keys.contains(method) {
            return self.CRUDSpecificCachePolicies[method]!
        }
        
        return self.CachePolicy
    }
    
    /**
    Returns all headers for a requested CRUD method. Merges CRUD specific headers with global
    headers. 
    
    - parameter method: ```Service.CRUDMethod```
    
    - returns: A ```HTTPHeaderDictionary```
    */
    public func allHTTPHeadersForMethod(method: Service.CRUDMethod) -> HTTPHeaderDictionary {
        var headers = self.HTTPHeaders;
        
        for (key, value) in self.CRUDSpecificHTTPHeaders[method] ?? [:] {
            headers.updateValue(value, forKey: key)
        }
        
        return headers
    }
    
    /**
    Provides a copy of this ServiceRealm. Used for overriding configuration. 
    
    **NOTDE:** Realm returned by this method will not be accesible using ```.get(key)```
    
    - returns: Cloned ```ServiceRealm```
    */
    internal func clone() -> ServiceRealm {
        let newRealm = ServiceRealm()
        newRealm._cachePolicy = self._cachePolicy
        newRealm._crudMethodMap = self._crudMethodMap
        newRealm._crudSpecificCachePolicies = self._crudSpecificCachePolicies
        newRealm._crudSpecificHeaders = self._crudSpecificHeaders
        newRealm._headers = self._headers
        newRealm._id = NSUUID().UUIDString
        newRealm._key = self._key
        
        return newRealm
    }
    
    /**
    Returns a realm for a given key. If no realm corresponds to that key, a new default
    one is created and returned.
    
     - parameter key: A key for which the realm is registered.
     - returns: A ```ServiceRealm``` for the given key.
    */
    public class func get(key: String) -> ServiceRealm {
        if !realms.keys.contains(key) {
            let realm = ServiceRealm()
            realm._key = key
            
            realms[key] = realm
        }
        return realms[key]!
    }
    
    /**
    Returns a default realm. All services use this realm, unless they are
    registered for a different one.
    
    **NOTE:** Overriding any configuration of this realm will influence all services 
    which were not explicitly registered for another realm. This may be considered
    an easy way of changing global configuration of outgoing requests. 
    
    - returns: Default ```ServiceRealm```
    */
    public class func getDefault() -> ServiceRealm {
        return defaultRealm
    }
    
    /**
    Registers a service for a realm at a given key. 
    
    Equivalent to ```ServiceRealm.get(key).register(service)``` call.
    
     - parameter service: Service to be registered
     - parameter key: Key of the realm to register the service for
    */
    public class func registerService(service: Service, forRealmAtKey key: String) {
        ServiceRealm.get(key).register(service)
    }
}