//
//  DIVESDKCommon.swift
//  DIVESDK
//
//  Created by AKorotkov on 20.12.2022.
//

import Foundation

@objc public protocol DIVESDKDelegate: AnyObject {
    func diveSDKResult(sdk: Any, result: [String : Any])
    func diveSDKError(sdk: Any, error: Error)
    func diveSDKSendingDataStarted(sdk: Any)
    func diveSDKSendingDataProgress(sdk: Any, progress: Float, requestTime: TimeInterval)
}

public extension DIVESDKDelegate {
    func diveSDKSendingDataProgress(sdk: Any, progress: Float, requestTime: TimeInterval) { }
}

public typealias DIVESDKResult = Result<[String : Any], Error>

public enum DIVEError: LocalizedError {
    case somethingWentWrong(Int? = nil)
    case configIsNotReady
    
    public var errorDescription: String? {
        switch self {
            case .somethingWentWrong(let statusCode):
                if let statusCode = statusCode {
                    return "Something Went Wrong\n(statusCode: \(statusCode))"
                } else {
                    return "Something Went Wrong"
                }
            case .configIsNotReady:
                return "Configuration is not ready"
        }
    }
}

import Alamofire

public struct DIVENetwork {
    public static func request(url: String, method: HTTPMethod, parameters: Parameters? = nil, token: String? = nil, completionHandler: @escaping (DIVESDKResult) -> Void, progressHandler: ((Float, TimeInterval) -> Void)? = nil) {
        var headers: [HTTPHeader] = []
        if let token = token {
            let authHeader = HTTPHeader.authorization(bearerToken: token)
            headers.append(authHeader)
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        AF.request(URL(string: url)!, method: method, parameters: parameters, encoding: JSONEncoding.default, headers: HTTPHeaders(headers)).response { result in
            switch result.result {
                case .success(let data):
                    if let statusCode = result.response?.statusCode, statusCode != 200 {
                        completionHandler(.failure(DIVEError.somethingWentWrong(statusCode)))
                    } else if let resultDic = data?.jsonToDictionary() {
                        completionHandler(.success(resultDic))
                    } else {
                        completionHandler(.failure(DIVEError.somethingWentWrong()))
                    }
                case .failure(let error):
                    completionHandler(.failure(error))
            }
        }.uploadProgress { progress in
            if let progressHandler = progressHandler {
                let seconds = (CFAbsoluteTimeGetCurrent() - startTime)
                progressHandler(Float(progress.completedUnitCount) / Float(progress.totalUnitCount), seconds)
            }
        }
        
    }
}

import IDScanCapture

public extension IDScanIDCaptureResult {
    var requestParams: [String : Any] {
        var model: [String : Any] = [:]
        if let frontImage = self.frontImage?.toBase64() {
            model["frontImageBase64"] = frontImage
        }
        if let backImage = self.backImage?.toBase64() {
            model["backOrSecondImageBase64"] = backImage
        }
        if let faceImage = self.faceImage?.toBase64() {
            model["faceImageBase64"] = faceImage
        }
        if let trackString = self.trackString {
            model["trackString"] = trackString
        }
        model["documentType"] = self.documentType
        
        return model
    }
}

import UIKit

internal extension UIImage {
    func toBase64() -> String {
        return self.jpegData(compressionQuality: 1)?.base64EncodedString() ?? ""
    }
}

extension Data {
    func jsonToDictionary() -> [String: Any]? {
        do {
            return try JSONSerialization.jsonObject(with: self, options: []) as? [String: Any]
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
}
