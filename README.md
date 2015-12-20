# iService

[![build](https://travis-ci.org/theddnc/iService.svg?branch=master)](https://travis-ci.org/theddnc/iService)
[![CocoaPods](https://img.shields.io/cocoapods/v/iService.svg)](https://cocoapods.org/pods/iService)
[![CocoaPods](https://img.shields.io/cocoapods/l/iService.svg)](https://cocoapods.org/pods/iService)
[![CocoaPods](https://img.shields.io/cocoapods/p/iService.svg)](https://cocoapods.org/pods/iService)
[![CocoaPods](https://img.shields.io/cocoapods/metrics/doc-percent/iService.svg)](http://cocoadocs.org/docsets/iPromise/0.0.1/)

RESTful interfaces made simple. 

## Installation

Copy this line into your podfile:

```pod 'iPromise', '~> 1.1'```

Make sure to also add ```!use_frameworks```

## Description

iService provides two classes: ```Service``` which is a representation of a RESTful Service
and a ```ServiceRealm``` which is a container for shared request configuration. 

#### Service

```Service``` class provides a CRUD (Create, Retrieve, Update, Destroy) interface for interacting
with RESTful APIs. Each CRUD method returns a ```Promise``` from [iPromise](https://github.com/theddnc/iPromise)

```Swift
let userService = Service(baseUrl: NSURL(string: "jsonplaceholder.typicode.com/users")!)

// does a GET on https://jsonplaceholder.typicode.com/users/1?
userService.retrieve("1").then({ result in
    let request = result.request    // NSURLRequest
    let response = result.response  // NSHTTPURLResponse
    let data = result.data          // NSData
    let error = result.error        // NSError
})
```

Services can register themselves in a Realm to use shared request cofiguration:

```Swift
ServiceRealm.get("jsonplaceholder").register(userService)

// or 
ServiceRealm.register(userService, forRealmAtKey: "jsonplaceholder")

// or 
userService.registerForRealm(ServiceRealm.get("jsonplaceholder"))
```

Configuration from ```ServiceRealm``` can be overriden on a per-request basis.

```Swift
let user = "{\"userId\": 1}".dataUsingEncoding(NSUTF8StringEncoding)!

// let's add some headers
userService
    .override({ configuration
        configuration.addHeader("Content-Type", withValue: "application/json")
    })
    .create(user)
    .then({ result in
        //...
    })

// this request will not inherit headers from previous call
userService
    .retrieve("1")
    .then({ result in
        //...
    })
```

#### ServiceRealm

```ServiceRealm``` is a container for common configuration, e.g.:

- request authorization
- content types
- accepted languages

```ServiceRealm``` provides a map of CRUD-HTTP methods, that can be overriden:

```Swift
static public let defaultCRUDMap: CRUDMap = [
    .CREATE:    .POST,
    .RETRIEVE:  .GET,
    .UPDATE:    .PUT,
    .DESTROY:   .DELETE
]

// override by calling
public func overrideCrudMap(map: CRUDMap) -> ServiceRealm

//or
public func overrideCrudMethod(method: Service.CRUDMethod, withHTTPMethod httpMethod: Service.HTTPMethod) -> ServiceRealm
```

HTTP headers can be configured globally, or per CRUD method:

```Swift
public typealias HTTPHeaderDictionary = [String: String]

public func addHeader(header: String, withValue value: String) -> ServiceRealm 
public func addHeaders(headers: HTTPHeaderDictionary) -> ServiceRealm
public func addHeader(header: String, withValue value: String, specificForCRUDMethod crudMethod: Service.CRUDMethod) -> ServiceRealm
public func addHeaders(headers: HTTPHeaderDictionary, specificForCRUDMethod crudMethod: Service.CRUDMethod) -> ServiceRealm
```

Same goes for cache policy:

```Swift
public func overrideGlobalCachePolicy(cachePolicy: NSURLRequestCachePolicy) -> ServiceRealm
public func overrideCachePolicy(cachePolicy: NSURLRequestCachePolicy, forCrudMethod method: Service.CRUDMethod) -> ServiceRealm
```

Configuration calls can be chained, so that full workflow looks like this:

```Swift
let userService = Service(baseUrl: NSURL(string: "jsonplaceholder.typicode.com/users")!)

ServiceRealm.get("jsonplaceholder")
    .addHeaders([
        "Authorization": "Token sagsrbiusd90322sdf4f3gd4",
        "Content-Type": "application/json",
    ])
    .addHeader("Accept-Language", withValue: "en", specificForCRUDMethod: .RETRIEVE)
    .overrideGlobalCachePolicy(NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData)
    .register(userService)

userService.retrieve("1").then({ result in
    // ...
})
```

## Documentation

Documentation is available [here](http://cocoadocs.org/docsets/iService/0.0.1/)

## Licence

See ```LICENCE```