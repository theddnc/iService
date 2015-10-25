//
//  ResourceRealm.swift
//  iPromise
//
//  Created by jzaczek on 30.10.2015.
//  Copyright © 2015 jzaczek. All rights reserved.
//

import Foundation

/**
A ResourceRealm is an entry point for configuration of Resources.

After creating and configuring a realm, Resources can be registered for it, and configuration
provided will be used for every request. 

For example, if an API protects some of its resources
with APIKey authentication and some are publicly available, two realms can be created:
 - first for publicly available resources, e.g. ```ResourceRealm.getDefault()```
 - second one for resources hidden behind APIKey, with appropriate headers set
    ```
    ResourceRealm.get("www.example.com/hidden").addHeaders(
        ["Authentication": "ApiKey (...)"]
    )
    ```

Supported configuration options:
 - CRUD method - HTTP method map - for APIs that do not conform to the default
    (or the most sane) CRUD - HTTP mapping
 - HTTP headers
 - CRUD method specific HTTP headers - for APIs that use some weird and 'legacy' 
    interfaces which make use of HTTP headers
*/
public class ResourceRealm {
    /// Type representing a map of CRUD methods and their corresponding HTTP methods
    public typealias CRUDMap = [Resource.CRUDMethod: Resource.HTTPMethod]
    
    /// Type representing a dictionary of HTTP headers
    public typealias HTTPHeaderDictionary = [String: String]
    
    /// Array of user defined ResourceRealms
    static private var realms: [String: ResourceRealm] = [:]
    
    /// Default realm with default configuration. All resources use this configuration, unless
    /// registered for a different realm.
    static private var defaultRealm: ResourceRealm = ResourceRealm()
    
    /// Resources registered for this realm
    private var _resources: [Resource] = []
    
    /// Dictionary of HTTP headers to add to every request coming out of this realm
    private var _headers: HTTPHeaderDictionary
    
    /// Global cache policy for this realm
    private var _cachePolicy: NSURLRequestCachePolicy
    
    /// Map of CRUD methods and their corresponding HTTP headers
    private var _crudSpecificHeaders: [Resource.CRUDMethod: HTTPHeaderDictionary]
    
    /// Map of CRUD methods and their corresponding cache policies
    private var _crudSpecificCachePolicies: [Resource.CRUDMethod: NSURLRequestCachePolicy]
    
    /// CRUD method - HTTP method map
    private var _crudMethodMap: CRUDMap
    
    /// Identifier for this realm
    private var _id: String = NSUUID().UUIDString
    
    /// User-defined key for this realm
    private var _key: String = ""
    
    /// Contains unique id for this realm, read only
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
    public var CRUDSpecificHTTPHeaders: [Resource.CRUDMethod: HTTPHeaderDictionary] {
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
    public var CRUDSpecificCachePolicies: [Resource.CRUDMethod: NSURLRequestCachePolicy] {
        get {
            return _crudSpecificCachePolicies
        }
    }
    
    /// Creates a default realm
    private init() {
        _headers = [:]
        _crudSpecificHeaders = ResourceRealm.getDefaultCrudHeaders()
        _crudMethodMap = ResourceRealm.getDefaultCrudMap()
        _cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
        _crudSpecificCachePolicies = [:]
    }
    
    /**
    Overrides default CRUD method - HTTP method map with passed argument
    
     - parameter map: A dictionary of type ```[Resource.CRUDMethod: Resource.HTTPMethod]```
    */
    public func overrideCrudMap(map: CRUDMap) {
        self._crudMethodMap = map
    }
    
    /**
    Overrides CRUD method with HTTP method passed as the argument.
    
     - parameter method: CRUD method to override. See ```Resource.CRUDMethod```
     - parameter httpMethod: HTTP method to override. See ```Resource.HTTPMethod```
    */
    public func overrideCrudMethod(method: Resource.CRUDMethod, withHTTPMethod httpMethod: Resource.HTTPMethod) {
        self._crudMethodMap.updateValue(httpMethod, forKey: method)
    }
    
    /**
    Adds a single header value to HTTP header dictionary
    
     - parameter header: HTTP header field name
     - parameter value: Value of the HTTP header field
    */
    public func addHeader(header: String, withValue value: String) {
        self._headers.updateValue(value, forKey: header)
    }
    
    /**
    Adds multiple headers to HTTP header dictionary. If a header from ```headers``` parameter is already
    defined, its value is set to a corresponding value from ```headers```.
    
     - parameter headers: Dictionary of headers to be merged with internal HTTP header dictionary
    */
    public func addHeaders(headers: HTTPHeaderDictionary) {
        for (key, value) in headers {
            self._headers.updateValue(value, forKey: key)
        }
    }
    
    /**
    Adds a single header value to HTTP header dictionary for a specific CRUD method
    
     - parameter header: HTTP header field name
     - parameter value: Value of the HTTP header field
     - parameter method: See ```Resource.CRUDMethod```
    */
    public func addHeader(header: String, withValue value: String, specificForCRUDMethod crudMethod: Resource.CRUDMethod) {
        self._crudSpecificHeaders[crudMethod]?.updateValue(value, forKey: header)
    }
    
    /**
    Adds multiple headers to HTTP header dictionary for a specific CRUD method. If a header from ```headers``` 
    parameter is already defined, its value is set to a corresponding value from ```headers```.
    
     - parameter headers: Dictionary of headers to be merged with internal HTTP header dictionary
     - parameter method: See ```Resource.CRUDMethod```
    */
    public func addHeaders(headers: HTTPHeaderDictionary, specificForCRUDMethod crudMethod: Resource.CRUDMethod) {
        for (key, value) in headers {
            self._crudSpecificHeaders[crudMethod]?.updateValue(value, forKey: key)
        }
    }
    
    /**
    Overrides global cache policy. Policies for CRUD methods can be overriden separately
    and have higher priority.
    
     - parameter cachePolicy: ```NSURLRequestCachePolicy``` to be set as default
    */
    public func overrideGlobalCachePolicy(cachePolicy: NSURLRequestCachePolicy) {
        self._cachePolicy = cachePolicy
    }
    
    /**
    Overrides CRUD method specific cache policy. This policy has a higher priority 
    than the global policy.
    
    - parameter cachePolicy: ```NSURLRequestCachePolicy``` to be set for this method
    - parameter method: See: ```Resource.CRUDMethod```
    */
    public func overrideCachePolicy(cachePolicy: NSURLRequestCachePolicy, forCrudMethod method: Resource.CRUDMethod) {
        self._crudSpecificCachePolicies.updateValue(cachePolicy, forKey: method)
    }
    
    /**
    Register a resource in this ```ResourceRealm```. 
    
    Registering in a resource realm provides an entry point for configuration.
    
    - parameter resource: ```Resource``` to be registered for this configuration
    */
    public func register(resource: Resource) {
        resource.registerForRealm(self)
    }
    
    /**
    Returns a realm for a given key. If no realm corresponds to that key, a new default
    one is created and returned.
    
     - parameter key: A key for which the realm is registered.
     - returns: A ```ResourceRealm``` for the given key.
    */
    public class func get(key: String) -> ResourceRealm {
        if !realms.keys.contains(key) {
            let realm = ResourceRealm()
            realm._key = key
            
            realms[key] = realm
        }
        return realms[key]!
    }
    
    /**
    Registers a resource for a realm at a given key. 
    
    Equivalent to ```ResourceRealm.get(key).register(resource)``` call.
    
     - parameter resource: Resource to be registered
     - parameter key: Key of the realm to register the resource for
    */
    public class func registerResource(resource: Resource, forRealmAtKey key: String) {
        ResourceRealm.get(key).register(resource)
    }
    
    /**
    Returns a default realm. All resources use this realm, unless they are
    registered for a different one. 
    
    **NOTE:** Overriding any configuration of this will influence all resources which were not
    explicitly registered for another realm. Be careful.
    
     - returns: Default ```ResourceRealm```
    */
    public class func getDefault() -> ResourceRealm {
        return defaultRealm
    }
    
    /**
    Returns default CRUD method - HTTP method map: 
    
    ```
    [
        .CREATE:    .POST,
        .RETRIEVE:  .GET,
        .UPDATE:    .PATCH,
        .DESTROY:   .DELETE,
    ]
    ```
    
     - returns: A default ```CRUDMap``` dictionary
    */
    public class func getDefaultCrudMap() -> CRUDMap {
        return [
            .CREATE:    .POST,
            .RETRIEVE:  .GET,
            .UPDATE:    .PATCH,
            .DESTROY:   .DELETE,
        ]
    }
    
    /**
    Returns default CRUD specific headers dictionary: 
    
    ```
    [
        .CREATE:    [:],
        .RETRIEVE:  [:],
        .UPDATE:    [:],
        .DESTROY:   [:]
    ]
    ```
    
     - returns: Default ```[Resource.CRUDMethod: HTTPHeaderDictionary]```
    */
    public class func getDefaultCrudHeaders() -> [Resource.CRUDMethod: HTTPHeaderDictionary] {
        return [
            .CREATE:    [:],
            .RETRIEVE:  [:],
            .UPDATE:    [:],
            .DESTROY:   [:]
        ]
    }
}