//
//  NetworkEngine.swift
//  ImgurStarter
//
//  Created by Stuart Levine on 5/26/18.
//  Copyright © 2018 Wildcat Productions. All rights reserved.
//

import Foundation
import UIKit

typealias ProgressBlock = (Double)->()
typealias ImageDownloadForCellCompletionBlock = (IndexPath?)->()
typealias ImageDownloadCompletionBlock = (UIImage?)->()

////
// To provide flexibility, this enum will accommodate normal GET, PUT, POST and DELETE requests
// The two other special cases provide for downloading images used in the collection view cells
// and uploading of a single image
//
enum NetworkTaskType {
    case normal
    case imageDownloadForCell(indexPath: IndexPath, image: ImgurImage)
    case imageDownload(image: ImgurImage)
    case imageUpload
}

////
// The main operation queue for requests.  This is a background serial queue
//
let operationQ: OperationQueue = {
    let opQueue = OperationQueue()
    opQueue.qualityOfService = .background
    opQueue.maxConcurrentOperationCount = 1
    return opQueue
}()

////
// This protocol ensures that the image model provides the proper parameters
// required for the async downloading of images for each collection view cell
// and to provide the progress of each cell's image download
//
protocol NetworkDataEngineProtocol {
    var downloadState: ImageDownloadState { get set }
    var percentComplete: Double { get set }
}

////
// A NetworkEngine providing URLSession and URLSessionDataTask requests
//
class NetworkEngineDataTask: NSObject {

    var data = Data()
    var completionBlock: CompletionBlock?
    var imageDownloadForCellCompletionBlock: ImageDownloadForCellCompletionBlock?
    var imageDownloadCompletionBlock: ImageDownloadCompletionBlock?
    var progressBlock: ProgressBlock?
    var taskType: NetworkTaskType
    var dataTask: URLSessionDataTask?
    var indexPath: IndexPath?
    var request: URLRequest?
    var image: ImgurImage?
    var session: URLSession!
    var bytesSent: Int64 = 0

    init(taskType: NetworkTaskType, request: URLRequest? = nil) {
        self.taskType = taskType
        switch taskType {
        case .imageDownloadForCell(let indexPath, let image):
            self.indexPath = indexPath
            self.image = image
        case .imageDownload(let image):
            self.image = image
        default: break
        }

        if let request = request {
            self.request = request
        }
        else if let image = self.image, let url = URL(string: image.link) {
            self.request = URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 30.0)
        }
    }

    func startDataTask() {
        guard let request = self.request else { return }
        if let image = image {
            image.downloadState = .downloading
        }
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        session = URLSession(configuration: config, delegate: self, delegateQueue: operationQ)
        dataTask = session.dataTask(with: request)
        dataTask?.resume()
    }

    //MARK: Utility

    func pauseDataTask() {
        dataTask?.suspend()
    }

    func cancelDataTask() {
        dataTask?.cancel()
    }

    func resumeDataTask() {
        dataTask?.resume()
    }

    ////
    // because the Imgur API does not provide error responses in the dataTask response object, we need to
    // check the "status" and "success" keys for errors.  And, if the status code
    // is anything but 200, 201, etc, then we must return an error response providing the message from
    // the data->error string
    //
    func didReceiveErrorResponse(from response: Any?) -> Bool {
        var isError = false
        if let jsonDict = response as? [String: Any], let success = jsonDict["success"] as? Bool, let statusCode = jsonDict["status"] as? Int {
            // Check for error response code in the json response
            if statusCode >= 400 {
                let errorMessage = (jsonDict["data"] as? [String: Any])?["error"] as? String ?? "An error occurred while attempting to fulfill your reqeust."
                completionBlock?(ImgurResponse.error(ImgurClient.generateError(code: statusCode, message: errorMessage)))
                isError = true
            }
        }
        return isError
    }
}

////
// URLSessionDataDelegate - provides methods for the various states of the data task
// - didReceiveData
// - didCompleteWithError
// - didSendBodyData
//
extension NetworkEngineDataTask: URLSessionDataDelegate {

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.data.append(data)
        if self.progressBlock != nil, let expectedContentLength = dataTask.response?.expectedContentLength, expectedContentLength > 0 {
            let percentComplete = Double(self.data.count) / Double(expectedContentLength)
            self.image?.percentComplete = percentComplete
            self.progressBlock?(percentComplete)
        }

    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {

        self.bytesSent += bytesSent
        if totalBytesExpectedToSend > 0 {
            let percentComplete = Double(self.bytesSent) / Double(totalBytesExpectedToSend)
            self.progressBlock?(percentComplete)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            image?.downloadState = .failed
            completionBlock?(.error(error))
        }
        else {
            image?.downloadState = .downloaded
            if self.data.count > 0 {
                switch self.taskType {
                case .normal, .imageUpload:
                    let jsonData = try? JSONSerialization.jsonObject(with: data, options: [])
                    if !self.didReceiveErrorResponse(from: jsonData) {
                        completionBlock?(ImgurResponse.success(jsonData))
                    }
                case .imageDownloadForCell(_, _):
                    let image = UIImage(data: self.data)
                    self.image?.thumbnail = image?.scaleImage(to: 150)
                    imageDownloadForCellCompletionBlock?(self.indexPath)
                case .imageDownload(_):
                    let image = UIImage(data: self.data)
                    imageDownloadCompletionBlock?(image)
                }
            }
        }
    }
}
