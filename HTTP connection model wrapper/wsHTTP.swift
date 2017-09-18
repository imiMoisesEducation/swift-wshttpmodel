//
//  wsHTML.swift
//  jsonParser2
//
//  Created by venta on 3/4/17.
//  Copyright © 2017 admin. All rights reserved.
//

import Foundation
import UIKit



protocol tempWSHTTPDelegate{
    func errorMessage(errorAlert: UIAlertController, code: Int)
}

protocol WSCustomDataConvertible{
    func getData()->Data
}

protocol WSCustomAsynchDataConvertible: WSCustomDataConvertible{
    func getData(_ callback: @escaping (Data)->())
}

extension WSCustomAsynchDataConvertible{
    func getData(_ callback: @escaping (Data)->()){
        DispatchQueue.global(qos: .userInteractive).async{
            callback(self.getData())
        }
    }
}

protocol WSIndicatesHTTPContentType: WSCustomDataConvertible {
    var contentType: String{get}
}

protocol WSCustomDictionaryConvertible{
    func getDictionary()->[String:Any]
}



protocol RawAttributedData: WSCustomDataConvertible{
    func getDictionary()->[String:Any]
}

protocol WSMultipartRawDataConvertible{
    func getMultipartData()->(variableData: WSCustomDictionaryConvertible, attributedRawData: [WSHTTPAttributedRawData])
}

enum WSHTTPJsonData<D:WSCustomDictionaryConvertible,A:Sequence>: WSIndicatesHTTPContentType{
    
    case dictionary(D)
    case array(A)
    
    init(_ d: D){
        self = .dictionary(d)
    }
    
    var contentType: String{
        get{
            return "application/json"
        }
    }
    
    func getData()->Data{
        switch  self {
        case let .dictionary(data):
            return try! JSONSerialization.data(withJSONObject: data, options: [])
        default:
            return Data()
        }
    }
}

enum WSHTTPLinkData<D:WSCustomDictionaryConvertible,A:Sequence>: WSCustomDataConvertible{
    case dictionary(D)
    case array(A)
    
    init(_ d:D){
        self = .dictionary(d)
    }
    
    func getData()->Data{
        switch  self {
        case let .dictionary(data):
            var bodyData = ""
            for (key,value) in data.getDictionary(){
                let scapedKey = key.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
                let scapedValue = (value as AnyObject).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
                bodyData += "\(String(describing: scapedKey))=\(String(describing: scapedValue))&"
            }
            return bodyData.data(using: String.Encoding.utf8, allowLossyConversion: true)!
        default:
            return Data()
        }
    }
}

protocol WSHTTPAttributedRawData:WSCustomDataConvertible{
    var fileName: String{set get}
    var mimeType: String{set get}
    var name: String{set get}
}

final class WSHTTPMultipartData:WSIndicatesHTTPContentType{
    
    internal struct Constants{
        static var lineBreak = "\r\n"
        static var boundary = "Boundary-------------------------------"
        
        static func appendDictionary(data: inout Data, variableStringData: inout Dictionary<String,Any>){
            for (k,v) in variableStringData{
                data.append("--\(boundary + lineBreak)")
                data.append("Content-Disposition: form-data; name=\"\(k)\"\(lineBreak + lineBreak)")
                data.append(String(describing: v))
                data.append(lineBreak)
            }
        }
        static func appendData(data: inout Data, attributedRawData: inout Array<WSHTTPAttributedRawData>){
            for (file) in attributedRawData{
                data.append("--\(boundary + lineBreak)")
                data.append("Content-Disposition: form-data; name=\"\(file.name)\"; filename=\"\(file.name)\"\(lineBreak)")
                data.append("Content-Type: \(file.mimeType + lineBreak + lineBreak)")
                data.append(file.getData())
                data.append(lineBreak)
            }
        }
    }
    
    var variableStringData: Dictionary<String,Any>
    var attributedRawData: Array<WSHTTPAttributedRawData>
    
    var contentType: String{
        get{
            return "multipart/form-data; boundary=\(Constants.boundary)"
        }
    }
    
    init(variableStringData: WSCustomDictionaryConvertible, attributedRawData:[WSHTTPAttributedRawData])
    {
        self.variableStringData = variableStringData.getDictionary()
        self.attributedRawData = attributedRawData
    }
    convenience init(multipartRawData: WSMultipartRawDataConvertible){
        let multipartRawData = multipartRawData.getMultipartData()
        self.init(variableStringData: multipartRawData.variableData, attributedRawData: multipartRawData.attributedRawData)
    }
    
    func getData()->Data{
        var body = Data()
        
        Constants.appendDictionary(data: &body, variableStringData: &variableStringData)
        Constants.appendData(data: &body, attributedRawData: &attributedRawData)
        body.append("--\(Constants.boundary)--\(Constants.lineBreak)")
        return body
    }
}

enum WSHTTPReqResults<T>{
    
    /// A successfull request
    case success(result: T, codetype: Int)
    /// Represents a client error
    case failed(errorMessage: CustomStringConvertible, codetype: Int?)
    /// Represents a server error
    
    /**
     Default constructor
     
     - Parameter code: An integer that repepresents an HTTP Code
     */
    init(result: T, code: Int){
        self = .success(result: result, codetype: code)
    }
    
    init(error: CustomStringConvertible, code: Int?){
        self = .failed(errorMessage: error, codetype: code)
    }
    
}

enum WSHTTPRequestType: String{
    ///Represents the POST method
    case POST
    ///Represents the GET method
    case GET
    ///Represents the PUT method
    case PUT
    ///Represents the DELETE method
    case DELETE
    ///Represents the PATCH method
    case PATCH
}

protocol WSSerializer{
}

func WSHTTPCreateRequest<T>(type: WSHTTPRequestType, url: URL, headers: [String:String], contentToSend: WSIndicatesHTTPContentType? = nil, callback: @escaping(WSHTTPReqResults<T>)->())->URLSessionDataTask{

    var request = URLRequest.init(url: url)
    
    //Adds the http method
    request.httpMethod = type.rawValue
    request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringCacheData

    //Adds the headers
    for (key,value) in headers{
        request.addValue(value, forHTTPHeaderField: key)
    }
    //If there is content, adds the content to send
    if let body = contentToSend{
        request.addValue(body.contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = body.getData()
    }
    
    //Does the request
    return URLSession.shared.dataTask(with: request)
    {
        (data, response, error) -> Void in
        let httpResponse = response as? HTTPURLResponse
        
        
        //If there is no response, it is because there was a conection problem
        guard httpResponse != nil else {
            callback(WSHTTPReqResults.init(error: "No internet Message", code: nil))
            return
        }
        
        //else, there is some status code
        let statusCode = httpResponse?.statusCode
        
        
        
        //if there was an error, handle it
        guard error == nil else{
            data?.copyBytes(to: <#T##UnsafeMutablePointer<UInt8>#>, count: <#T##Int#>)
            HTTPFindError(UnsafePointer<Data?>.init(bitPattern: &data), statusCode: statusCode!, callback: callback)
            return
        }
        
        
        
        if (statusCode! >= 200  && statusCode! < 300) {
            var datat: Data? = nil
            
            
            if  let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue){
                if let dataFromString = dataString.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: true) {
                    datat = dataFromString
                }
            }
            
            
            if datat == nil{
                let dataString = NSString(data: data!, encoding: String.Encoding.ascii.rawValue)
                if let dataFromString = dataString!.data(using: String.Encoding.ascii.rawValue, allowLossyConversion: true){
                    datat = dataFromString
                }
            }
            
            do{
                json = try JSONSerialization.jsonObject(with: datat!, options: [])
            }catch {
                
            }
        }else{
            var a = try? JSONSerialization.jsonObject(with: data!, options: [])
            if let b = a as? Dictionary<String,Any>{
                var alert: UIAlertController = .init(title: "Error", message: "\(b["message"]!)", preferredStyle: UIAlertControllerStyle.alert)
                
                
                var action: UIAlertAction = .init(title: "Ok", style: .default, handler: nil)
                alert.addAction(action)
                
                
                callback(json, wsHTTP.sender.codeType.init(code: statusCode!))
                DispatchQueue.main.async {
                    
                    delegate?.errorMessage(errorAlert: alert, code: statusCode!)
                    
                }
            }
            
            print()
        }
        callback(json, wsHTTP.sender.codeType.init(code: statusCode!))
    }
    
    
    
    
}




/**
 A Singleton Struct that supports basic network operations through HTTP Protocol
 */
struct WSHTTP{

    
    static var delegateWindow: UIWindow? = nil
    static var delegate: tempWSHTTPDelegate? = nil
    /**
     A dictionary containing all possible HTTP status codes
     */
    //static var booleano = true
    static private let status = [200:"OK",201:"Created",202:"Accepted",203:"Non-Authoritative Information",204:"No Content",205:"Reset Content", 206:"Partial Content", 207:"Multi-Status",208:"Already Reported",400:"Bad Request",401:"Unauthorized",402:"Payment Required",403:"Forbidden",404:"Not Found",405:"Method Not Allowed",406: "Not Acceptable", 407: "Proxy Authentication Required", 408:"Request Timeout", 409: "Conflict",410: "Gone", 411: "Length Required", 412: "Precondition Failed", 413: "Request Entity",414:"Request-URI Too Long",415:"Unsuported Media Type", 416:"Requested Range Not Satisfiable",417:"Expectation Failed",418: "I'm a teapot", 422:"Unprocessable Entity",423:"Locked",424:"Failed Dependency",425:"Unassigned",426:"Upgrade Required",428:"Too Many Requests",431: "Request Header Fields Too Large",449:"",451:"Unavailable for Legal Reasons",500:"Internal Server Error",501:"Not Implemented",502:"Bad Gateway",503:"Service Unavailable", 504:"Gateway Timeout", 505:"HTTP Version Not Supported",506:"Variant Also Negociates",507:"Insufficient Storage",508:"Loop Detected", 509:"Bandwith Limit Exceeded", 510:"Not Extended",511:"Network Authentication Required",512: "Not Updated"]
    
    /**
     Here is where user defined behaviors are stored
     */
    static var userDefinedBehaviors: Dictionary<String,(code: [Int],foo: (@escaping ()->(),String)->Bool)> = Dictionary<String,([Int],(@escaping ()->(), String)->Bool)>()
    

        /**
         Represents the httpbody itself with its parameters
         # WARNING: #
         If you are going to build this enum into the request object, **use the .init() constructor instead**
         */
        case httpBody(httpRequestType,[String:Any],dataRepresentation)
        
        
        
        /**
         - Parameter method: **an httpRequest enum**, indicating the type of request that is going to be sent **e.g. .POST, .GET**
         - Parameter headers: **(Optional Parameter)** **a Dictionary<String,Any>**, with the headers that are going to be sent
         - Parameter data: **(Optional Parameter)**  **an dataRepresentation enum** indicating the data that is going to be sent, with a **Dictionary<String,Any>** as its only parameter
         */
        init(_ method: httpRequestType, headers: [String:Any] = [:], data: dataRepresentation = .noData) {
            self = .httpBody(method, headers, data)
        }
        
        
        /**
         Acording to the parameters of the selected enum, builds an HTTP request
         
         - Parameter url: The destination url of the request
         */
        func getRequest(url: String) -> URLRequest{
            let url = url.replacingOccurrences(of: " ", with: "%20")
            let u:URL = URL(string:url)!
            let request = NSMutableURLRequest(url: u)
            switch self
            {
            case let .httpBody(method, header, format):
                request.httpMethod = method.rawValue
                request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
                for (key,value) in header{
                    request.addValue("\(value)", forHTTPHeaderField: "\(key)")
                }
                switch format {
                case .json(_):
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                case .multipart(_):
request.setValue("multipart/form-data; boundary=\(wsHTTP.boundary)", forHTTPHeaderField: "Content-Type")
                default:
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                }
                request.httpBody = format.getData()
                
            }
            return request as URLRequest
        }
    
    
    /**
     sets behaviors in the singleton, to then be used in the request function
     
     - Parameter name: The new name of the behavior
     - Parameter htmlCode: a range of Int numbers representing the html codes to fetch
     - Parameter behavior: The function that will be excecuted, which takes no parameters nor arguments
     */
    static func setBehavior(name: String, htmlCode: CountableClosedRange<Int>, behavior:  @escaping (_ previousRequest: @escaping ()->(), _ AcessToken: String)->Bool){
        wsHTTP.userDefinedBehaviors.updateValue((.init(htmlCode),behavior), forKey: name)
    }
    
    /**
     sets behaviors in the singleton, to then be used in the request function
     
     - Parameter name: The new name of the behavior
     - Parameter htmlCode: an array of Int numbers representing the html codes to fetch
     - Parameter behavior: The function that will be excecuted, which takes no parameters nor arguments
     */
    static func setBehavior(name: String, htmlCode: [Int], behavior:  @escaping (_ previousRequest: @escaping ()->(), _ AccessToken: String)->Bool){
        wsHTTP.userDefinedBehaviors.updateValue((.init(htmlCode),behavior), forKey: name)
    }
    
    /**
     sets behaviors in the singleton, to then be used in the request function
     
     - Parameter name: The new name of the behavior
     - Parameter htmlCode: an Int number representing the html code to fetch
     - Parameter behavior: The function that will be excecuted, which takes no parameters nor arguments
     */
    static func setBehavior(name: String, htmlCode: Int, behavior: @escaping (_ previousRequest: @escaping ()->(), _ AccessToken: String)->Bool){
        wsHTTP.userDefinedBehaviors.updateValue(([htmlCode],behavior), forKey: name)
    }

    
    /**
     builds the actual request to a server using the HTTP Protocol and returns the task itself
     
     - Parameter url: **An String** with the destination url
     - Parameter with: **A wsHTTP.sender Enum**, please build it with its constructor
     - Parameter callback: The callback function, with 2 parameters (data, statscode) and no returns
     - Parameter dat: **A Dictionary<String,Any>** with the server answer, parsed with the chosen format (Json by default)
     - Parameter statusCode: **a wsHTTP.sender.codeType** with the answer's status code
     - Parameter behaviors: **A variadic String parameter** representing the set of behaviors of the request
     */
    static func requestTask<T>(url: String, with req: wsHTTP.sender, callback: @escaping (_ dat: Any?,_ statusCode: HTTPResults<T>) -> (), _ behaviors: String...) -> URLSessionDataTask
    {
        var newRequest = req.getRequest(url: url)
        return doRequestTask<T>(url: &newRequest, callback: callback, behaviors)
    }
    
    
    /**
     makes the actual request to a server using the HTTP Protocol within the wsHTTP struct
     
     - Parameter url: **An String** with the destination url
     - Parameter callback: The callback function, with 2 parameters (data, statscode) and no returns
     - Parameter dat: **A Dictionary<String,Any>** with the server answer, parsed with the chosen format (Json by default)
     - Parameter statusCode: **a wsHTTP.sender.codeType** with the answer's status code
     - Parameter behaviors: **A variadic String parameter** representing the set of behaviors of the request
     */
    static private func doRequestTask<T>(url: inout URLRequest, callback: @escaping (_ dat: Any?,_ statusCode: wsHTTP.sender.codeType) -> (), _ behaviors: [String]) -> URLSessionDataTask{
        
    }
    
    
    
    private static func buildAndShowMessage(Message: Dictionary<String,Any>, statusCode: Int){
        
        var alert: UIAlertController = .init(title: "Error", message: "\(Message["message"]!)", preferredStyle: UIAlertControllerStyle.alert)
        
        
        let action: UIAlertAction = .init(title: "Ok", style: .default, handler: nil)
        alert.addAction(action)
        DispatchQueue.main.async {
            
            delegate?.errorMessage(errorAlert: alert, code: statusCode)
            
        }
    }
}
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}





fileprivate func HTTPFindError<T>(_ data: UnsafePointer<Data?>, statusCode: Int, callback: @escaping(WSHTTPReqResults<T>)->()){
    do{
        var errorMessage = try? JSONSerialization.jsonObject(with: data.pointee, options: [])
        if let errorDictionary = errorMessage as? Dictionary<String,Any> {
            
            var message: Any
            
            if errorDictionary.contains(where: { (k,v) -> Bool in let r = k == "message"; if r{ message = v}; return r})
            {
                callback(WSHTTPReqResults.init(error: String(describing: message), code: statusCode))
            }
        }
    }catch{
        callback(WSHTTPReqResults.init(error: "Json couldnt be deserialized", code: statusCode))
    }
}



extension URL {
    /// Dictionary with key/value pairs from the URL fragment
    var fragmentDictionary: [String: String] {
        return dictionaryFromFormEncodedString(fragment)
    }
    
    /// Dictionary with key/value pairs from the URL query string
    var queryDictionary: [String: String] {
        return dictionaryFromFormEncodedString(query)
    }
    
    var fragmentAndQueryDictionary: [String: String] {
        var result = fragmentDictionary
        queryDictionary.forEach { (key, value) in
            result[key] = value
        }
        return result
    }
    
    private func dictionaryFromFormEncodedString(_ input: String?) -> [String: String] {
        var result = [String: String]()
        
        guard let input = input else {
            return result
        }
        let inputPairs = input.components(separatedBy: "&")
        
        for pair in inputPairs {
            let split = pair.components(separatedBy: "=")
            if split.count == 2 {
                if let key = split[0].removingPercentEncoding, let value = split[1].removingPercentEncoding {
                    result[key] = value
                }
            }
        }
        return result
    }
}
