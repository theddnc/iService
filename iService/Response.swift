//
//  Response.swift
//  iService
//
//  Created by jzaczek on 19.12.2015.
//  Copyright © 2015 jzaczek. All rights reserved.
//

import Foundation

/**
 ```ResponseBundle``` is a container for data that is related
 with a ```NSURLSessionDataTask```. It contains:

  - the ```NSURLRequest``` that initiated the data task
  - the ```NSURLResponse``` that was returned
  - the ```NSData``` from the response body
  - the ```NSErorr``` if there were any errors
*/
public class ResponseBundle {
    private var _request: NSURLRequest
    private var _response: NSHTTPURLResponse?
    private var _data: NSData?
    private var _error: NSError?
    
    /// Contains the ```NSURLRequest``` that initiated the data task
    public var request: NSURLRequest {
        get {
            return self._request
        }
    }
    
    /// Contains the ```NSHTTPURLResponse``` that was returned
    public var response: NSHTTPURLResponse? {
        get {
            return self._response
        }
    }
    
    /// Contains the ```NSData``` from response's body
    public var data: NSData? {
        get {
            return self._data
        }
    }
    
    /// Contains errors returned to the data task handler
    public var error: NSError? {
        get {
            return self._error
        }
    }
    
    /**
    Initializes ```ResponseBundle```.
     
     - parameter request: the ```NSURLRequest``` that initiated the data task
     - parameter response: the ```NSHTTPURLResponse``` that was returned
     - parameter data: the ```NSData``` from the response body
     - parameter error: the ```NSErorr``` if there were any errors
    */
    public init(request: NSURLRequest, response: NSHTTPURLResponse?, data: NSData?, error: NSError?) {
        self._request = request
        self._response = response
        self._data = data
        self._error = error
    }
}