//
//  ImgurAPIClient.swift
//  ImgurStarter
//
//  Created by Stuart Levine on 5/25/18.
//  Copyright © 2018 Wildcat Productions. All rights reserved.
//
//

import Foundation
import UIKit
import SafariServices

typealias CompletionBlock = (ImgurResponse)->()

////
// HTTP Protocol Methods
//
enum HTTPMethod: String {
    case get = "GET"
    case put = "PUT"
    case post = "POST"
    case delete = "DELETE"

    var stringValue: String {
        return self.rawValue
    }
}

////
// API Response Object
//
enum ImgurResponse {
    case success(Any?)
    case error(Error?)
}

////
// Endpoint Model Data - everything we need to make Imgur API Endpoint calls
//
// @param url - api endpoint url
// @param method - HTTPMethod (GET, PUT, POST and DELETE)
// @param headers - dictionary of header key value pairs (optional)
// @param body - Data used for POST methods (optional)
//
fileprivate struct EndpointData {
    var url: URL?
    var method: HTTPMethod
    var headers: [String: String]?
    var body: Data?
    var taskType: NetworkTaskType

    init(url: URL?, method: HTTPMethod, headers: [String: String]? = nil, body: Data? = nil, taskType: NetworkTaskType = .normal) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
        self.taskType = taskType
    }
}

////
// Main Imgur API Client class
//
class ImgurClient: NSObject {
    // class constants
    static let baseURL = "https://api.imgur.com/"
    static let apiVersion = "3"
    static let clientId = "4595eecc7ff640e"
    static let clientSecret = "455e4ff0442f657b4fc3f70ce135a3e347e0fb15"
    static let imagePerPage = 100 // default
    static let clientAuthorizationHeader = ["Authorization" : "Client-ID \(ImgurClient.clientId)"]

    // imgur user info
    static var user = ImgurUser()

    ////
    // Available Imgur Endpoints via an enum with associated paramters
    enum Endpoint {
        case authorization
        case images(page: Int)
        case imageCount
        case upload(photo: PhotoUpload)
        case delete(deletHash: String)

        fileprivate var data: EndpointData {
            switch self {
            case .authorization:
                let url = URL(string: "\(baseURL)oauth2/authorize/?client_id=\(clientId)&response_type=token")
                return EndpointData(url: url, method: .get)
            case .images(let page):
                let url = URL(string: "\(baseURL)\(apiVersion)/account/\(ImgurClient.user.username)/images/?perPage=\(ImgurClient.imagePerPage)&page=\(page)")
                return EndpointData(url: url, method: .get, headers: ImgurClient.user.authHeader)
            case .imageCount:
                let url = URL(string: "\(baseURL)\(apiVersion)/account/\(ImgurClient.user.username)/images/count")
                return EndpointData(url: url, method: .get, headers: ImgurClient.user.authHeader)
            case .upload(let photo):
                let body = try? JSONEncoder().encode(photo)
                let url = URL(string: "\(baseURL)\(apiVersion)/image")
                var headers = ImgurClient.user.authHeader
                headers["Content-Type"] = "application/json"
                return EndpointData(url: url, method: .post, headers: headers, body: body, taskType: .imageUpload)
            case .delete(deletHash: let deleteHash):
                let url = URL(string: "\(baseURL)\(apiVersion)/image/\(deleteHash)")
                return EndpointData(url: url, method: .delete, headers: ImgurClient.user.authHeader)
            }
        }
    }

    // Convenience method to provide an SFSafariViewController for Outh2 Authorization
    static func authorizationController() -> SFSafariViewController? {
        guard let authUrl = ImgurClient.Endpoint.authorization.data.url else { return nil }
        let safariViewController = SFSafariViewController(url: authUrl)
        return safariViewController
    }

    // Conveniece method to provide a default Error object in the case where we don't have one
    static func generateError(code: Int, message: String) -> Error {
        let infoDict = [NSLocalizedDescriptionKey : message]
        let error = NSError(domain: "com.wildcatproductions.error", code: code, userInfo: infoDict)
        return error
    }

    static let jsonEncoder = JSONEncoder()
    static let jsonDecoder = JSONDecoder()

    // URLSession
    fileprivate static let sessionConfig = URLSessionConfiguration.default
    fileprivate static let session = URLSession(configuration: sessionConfig)

    ////
    // Generate the URLRequest object
    //
    // @param endpoint Endpoint - the endpoint to use to construct the URLRequest
    //
    // @return URLRequest object
    //
    fileprivate static func request(with endpoint: EndpointData) -> URLRequest? {
        guard let url = endpoint.url else { return nil }

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 30)
        request.allHTTPHeaderFields = endpoint.headers
        request.httpMethod = endpoint.method.stringValue

        switch endpoint.method {
        case .put:
            request.httpBody = endpoint.body
        case .post:
            request.httpBody = endpoint.body
        default:
            break
        }

        return request
    }

    ////
    // The main method to make Imgur API Calls
    //
    // @param endpoint: APIURL.endpoint - providss the enum describing the API
    //                  Endpiint and Endpoint data to use
    // @param onCompletion: EndpointCompletionBlock - the optional completion
    //                      block to execute when the async data tasks has completed
    //
    // @result URLSessionDataTask - allows more control over the data task
    //
    @discardableResult static func apiCall(with endpoint: Endpoint, onCompletion: CompletionBlock?, progressBlock: ProgressBlock? = nil) -> NetworkEngineDataTask? {

        guard let request = ImgurClient.request(with: endpoint.data) else {
            let error = generateError(code: 404, message: "Invalid URL Found")
            onCompletion?(ImgurResponse.error(error))
            return nil
        }
        let dataTask = NetworkEngineDataTask(taskType: endpoint.data.taskType, request: request)
        dataTask.completionBlock = onCompletion
        dataTask.progressBlock = progressBlock
        dataTask.startDataTask()

        return dataTask
    }
}
