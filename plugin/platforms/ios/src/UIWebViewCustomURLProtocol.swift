//
//  UIWebViewCustomURLProtocol.swift
//  NotaWebViewExt
//
//  Created by Morten Anton Bach Sjøgren on 11/04/2018.
//  Copyright © 2018 Nota. All rights reserved.
//

import Foundation

@objc
public class CustomNSURLProtocol: URLProtocol,NSURLConnectionDelegate,URLSessionDelegate,URLSessionTaskDelegate {
    
    @objc
    override public class func canInit(with request: URLRequest) -> Bool {
        if let url = request.url, url.scheme == Constants.customURLScheme {
            return true
        }
        return false
    }
    
    @objc
    override public class func canInit(with task: URLSessionTask) -> Bool {
        let _ = task.currentRequest?.url
        return false
    }
    
    @objc
    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request;
    }
    
    @objc
    public static var resourceDict: [String: String] = [:];

    @objc
    public static func resolveFilePath(_ url: URL) -> String? {
        NSLog("CustomNSURLProtocol.resolveFilePath(%@)", url.absoluteString);
        if url.absoluteString.starts(with: Constants.customURLScheme) {
            let urlStr = url.host! + url.path
            NSLog("CustomNSURLProtocol.resolveFilePath(%@) - path(%@)", url.absoluteString, urlStr);
            if let filepath = CustomNSURLProtocol.getRegisteredLocalResource(forKey: urlStr) {
                NSLog("CustomNSURLProtocol.resolveFilePath(%@) - path(%@) - filepath(%@)", url.absoluteString, urlStr, filepath);
                return filepath
            }
        }
        NSLog("CustomNSURLProtocol.resolveFilePath(%@) - no match", url.absoluteString);
        return nil;
    }
    
    @objc
    public static func registerLocalResource(forKey: String, filepath: String) {
        self.resourceDict[forKey] = filepath;
    }
    
    @objc
    public static func unregisterLocalResource(forKey: String) {
        self.resourceDict.removeValue(forKey: forKey)
    }
    
    @objc
    public static func getRegisteredLocalResource(forKey: String) -> String? {
        return self.resourceDict[forKey]
    }
    
    @objc
    public static func clearRegisteredLocalResource() {
        self.resourceDict = [:]
    }
    
    @objc
    public func resolveMimeTypeFrom(filepath: String) -> String {
        let ext = URL(fileURLWithPath: filepath).pathExtension;
        NSLog("CustomNSURLProtocol.resolveMimeTypeFrom(%@) - ext(%@)", filepath, ext)
        if let mimetype = Constants.mimeType[ext] {
            NSLog("CustomNSURLProtocol.resolveMimeTypeFrom(%@) - ext(%@) -> mimetype(%@)", filepath, ext, mimetype)
            return mimetype
        }
        
        return "application/octet-stream"
    }

    @objc
    override public func startLoading() {
        DispatchQueue.global().async {
            guard let url = self.request.url, url.scheme == Constants.customURLScheme else {
                NSLog("CustomNSURLProtocol.startLoading() - invalid url")
                return;
            }
            NSLog("CustomNSURLProtocol.startLoading() - url(%@)", url.absoluteString)
            guard let filepath = CustomNSURLProtocol.resolveFilePath(url) else {
                NSLog("CustomNSURLProtocol.startLoading() - url(%@) did't resolve to a file", url.absoluteString)
                return;
            }
            guard let data = NSData.init(contentsOfFile: filepath) else {
                NSLog("CustomNSURLProtocol.startLoading() - url(%@) no data", url.absoluteString)
                return;
            }
            let mimeType = self.resolveMimeTypeFrom(filepath: filepath);
            let urlResponse = HTTPURLResponse.init(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": mimeType])
            
            self.client?.urlProtocol(self, didReceive: urlResponse!, cacheStoragePolicy: .notAllowed)
            self.client?.urlProtocol(self, didLoad: data as Data)
            self.client?.urlProtocolDidFinishLoading(self)
        }
    }
    
    @objc
    override public func stopLoading() {
        
    }
}
