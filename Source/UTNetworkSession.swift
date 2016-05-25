//
//  UTNetworkSession.swift
//  UTeacher
//
//  Created by Sebarina Xu on 8/5/15.
//  Copyright (c) 2015 icoolmocca. All rights reserved.
//

import Foundation
import AFNetworking

public typealias API_Completion_Success = (AnyObject?, NSURLResponse) -> Void
public typealias API_Completion_Failure = (NSError, NSURLResponse) -> Void
public typealias API_Progress_Block = (NSProgress) -> Void

typealias API_Log_Block = (AnyObject) -> Void

public enum UTNetworkStatus: Int {
    case Unknown
    case NotReachable
    case ReachableViaWWAN
    case ReachableViaWiFi
}

public enum UTNetworkSecurityMode {
    case None
    case PublicKey
    case Certificate
}


public class UTNetworkSession {
    
    ///  管理操作主类
    var manager : AFHTTPSessionManager
    
    var baseUrl : NSURL?
    
    ///  是否允许cache，默认NO
    var enableCache : Bool = false
    
    
    var log : API_Log_Block = {
        (obj: AnyObject) in
        #if DEBUG
            print("\(obj)")
            print("\n")
        #endif
    }
    
    public convenience init(baseUrl: String) {
        self.init(baseUrl: baseUrl, timeout: 10, enableCache: false, serviceType: .NetworkServiceTypeDefault)
    }
    public convenience init(baseUrl: String, timeout: NSTimeInterval) {
        self.init(baseUrl: baseUrl, timeout: timeout, enableCache: false, serviceType: .NetworkServiceTypeDefault)
    }
    
    
    public init(baseUrl: String, timeout: NSTimeInterval, enableCache: Bool, serviceType: NSURLRequestNetworkServiceType) {
        self.baseUrl = NSURL(string: baseUrl)
        self.enableCache = enableCache
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        configuration.networkServiceType = serviceType
        manager = AFHTTPSessionManager(baseURL: NSURL(string: baseUrl), sessionConfiguration: configuration)
        
    }
    
    public func securityPolicy(mode: UTNetworkSecurityMode) {
        var pinningMode : AFSSLPinningMode
        switch  mode {
        case .Certificate:
            pinningMode = AFSSLPinningMode.Certificate
            break
        case .PublicKey:
            pinningMode = AFSSLPinningMode.PublicKey
        default:
            pinningMode = AFSSLPinningMode.None
        }
        
        manager.securityPolicy = AFSecurityPolicy(pinningMode: pinningMode)
    }
    
    public func securityPolicy(mode: UTNetworkSecurityMode, pinnedCertificates: Set<NSData>) {
        var pinningMode : AFSSLPinningMode
        switch  mode {
        case .Certificate:
            pinningMode = AFSSLPinningMode.Certificate
            break
        case .PublicKey:
            pinningMode = AFSSLPinningMode.PublicKey
        default:
            pinningMode = AFSSLPinningMode.None
        }
        
        manager.securityPolicy = AFSecurityPolicy(pinningMode: pinningMode, withPinnedCertificates: pinnedCertificates)
    }
    
    
    public class func getNetworkStatus() -> UTNetworkStatus {
        let status = AFNetworkReachabilityManager.sharedManager().networkReachabilityStatus
        return UTNetworkStatus(rawValue: status.rawValue) ?? .Unknown
    }
    

    
    
    /**
    发起一个API数据请求

    */
    public func startOperationWithUrlString(urlString: String, method: String, params : [String: AnyObject]?, header: [String: String]?, success: API_Completion_Success, failure: API_Completion_Failure) {


        log( "API Request: " + urlString)
        if params != nil {
           log("PARAMS: " + params!.description)
        }
        var serializerError : NSError?
        let request : NSMutableURLRequest = manager.requestSerializer.requestWithMethod(method, URLString: NSURL(string: urlString, relativeToURL: baseUrl)?.absoluteString ?? urlString, parameters: params, error: &serializerError)
        
        if serializerError != nil {
            return
        }
        
        if header != nil {
            for (key,value) in header! {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        startOperationWithRequest(request, success: success, failure: failure)

    }
    
    /**
    发起一个API数据请求
    
    - parameter request: NSURLRequest请求
    - parameter block:   请求回调
    */
    public func startOperationWithRequest(request: NSURLRequest, success: API_Completion_Success?, failure: API_Completion_Failure?) {
        
        let task = manager.dataTaskWithRequest(request, completionHandler: { (response: NSURLResponse, obj: AnyObject?, error: NSError?) in
            if error == nil {
                success?(obj, response)
            } else {
                failure?(error!, response)
            }
        })
        
        
        // 是否保存本地缓存，默认情况下NSURLConnection会把response缓存在本地db内
        if !enableCache {
            manager.setDataTaskWillCacheResponseBlock({ (session: NSURLSession, task: NSURLSessionDataTask, response: NSCachedURLResponse) -> NSCachedURLResponse in
                return NSCachedURLResponse(response: response.response, data: response.data, userInfo: nil, storagePolicy: .AllowedInMemoryOnly)
            })
        }

        task.resume()
    }
    
    
    /**
    上传文件请求
    
    - parameter urlString: 上传Url
    - parameter fileData:  文件数据
    - parameter method:    请求方法
    - parameter block:     请求回调
    */
    public func startUploadWithData(urlString: String, fileData: NSData, filename: String, mimeType: String, progress: API_Progress_Block?, success: API_Completion_Success?, failure: API_Completion_Failure?) {
        log("upload file:\(filename)=== \(urlString)")
        var serializerError : NSError?
        let request : NSMutableURLRequest = manager.requestSerializer.multipartFormRequestWithMethod("POST", URLString: urlString, parameters: nil, constructingBodyWithBlock: { (data: AFMultipartFormData) in
            data.appendPartWithFileData(fileData, name: "file", fileName: filename, mimeType: mimeType)
            
            }, error: &serializerError)
        
            
        if serializerError != nil {
            return
        }
        
        startUploadRequest(request, progress: progress, success: success, failure: failure)
    }
    
    public func startUploadRequest(request: NSURLRequest, progress: API_Progress_Block?, success: API_Completion_Success?, failure: API_Completion_Failure?) {
        let task = manager.uploadTaskWithStreamedRequest(request, progress: progress, completionHandler: { (response: NSURLResponse, obj: AnyObject?, error: NSError?) in
            if error == nil {
                success?(obj, response)
            } else {
                failure?(error!, response)
            }
        })
        task.resume()
    }
    
    public func startDownloadWithUrl(urlString: String, parameters: [String: AnyObject]?, saveUrl: NSURL, progress: API_Progress_Block?, success: API_Completion_Success?, failure: API_Completion_Failure?) {
        log("Download file:\(urlString)=== \(saveUrl.absoluteString)")
        var serializerError : NSError?
        let request = manager.requestSerializer.requestWithMethod("GET", URLString: urlString, parameters: parameters, error: &serializerError)
        if serializerError != nil {
            return
        }        
    
        startDownloadRequest(request, saveUrl: saveUrl, progress: progress, success: success, failure: failure)
    }
    
    
    public func startDownloadRequest(request: NSURLRequest, saveUrl: NSURL, progress: API_Progress_Block?, success: API_Completion_Success?, failure: API_Completion_Failure?) {
        let task = manager.downloadTaskWithRequest(request, progress: progress, destination: { (url: NSURL, urlResponse: NSURLResponse) -> NSURL in
                return saveUrl
            }, completionHandler: { (res: NSURLResponse, url: NSURL?, error: NSError?) in
                if error == nil {
                    success?(url, res)
                } else {
                    failure?(error!, res)
                }
        })
        
        task.resume()
    }
    
    
}