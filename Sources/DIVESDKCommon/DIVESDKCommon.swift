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
    case custom(String)
    
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
            case .custom(let text):
                return text
        }
    }
}

public class DIVENetwork {
    private var observation: NSKeyValueObservation?
    deinit {
        observation?.invalidate()
    }
    public init() { }
    
    public func request(url: String, method: String, parameters: [String: Any]? = nil, token: String? = nil, completionHandler: @escaping (DIVESDKResult) -> Void, progressHandler: ((Float, TimeInterval) -> Void)? = nil) {
        let configuration = URLSessionConfiguration.default
//        configuration.timeoutIntervalForRequest = 45
//        configuration.timeoutIntervalForResource = 45
        if let token = token {
            configuration.httpAdditionalHeaders = ["Authorization": "Bearer \(token)"]
        }
        let session = URLSession(configuration: configuration)
        
        let url = URL(string: url)!
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        if let parameters = parameters {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            } catch _ { }
        }
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completionHandler(.failure(error))
                    return
                }
                
                if let data = data, let resultDic = self.parseData(data: data) {
                    if let response = response as? HTTPURLResponse, response.statusCode != 200 {
                        if let message = resultDic["message"] as? String {
                            completionHandler(.failure(DIVEError.custom(message)))
                        } else {
                            completionHandler(.failure(DIVEError.somethingWentWrong(response.statusCode)))
                        }
                        return
                    } else {
                        completionHandler(.success(resultDic))
                        return
                    }
                } else {
                    if let response = response as? HTTPURLResponse, response.statusCode != 200 {
                        completionHandler(.failure(DIVEError.somethingWentWrong(response.statusCode)))
                        return
                    }
                }
                
                completionHandler(.failure(DIVEError.somethingWentWrong()))
            }
        })
        
        if let progressHandler = progressHandler {
            self.observation = task.observe(\.countOfBytesSent) { progress, _ in
                let seconds = (CFAbsoluteTimeGetCurrent() - startTime)
                DispatchQueue.main.async {
                    progressHandler(Float(progress.countOfBytesSent) / Float(progress.countOfBytesExpectedToSend), seconds)
                }
            }
        }
        
        task.resume()
    }
    
    private func parseData(data: Data) -> [String: Any]? {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            if let resultDic = json as? [String: Any] {
                return resultDic
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
}

import IDScanCapture

@objc public class DIVESDKTheme: NSObject {
    var accentColor: UIColor
    var fontSizeModifier: CGFloat
    
    public init(accentColor: UIColor, fontSizeModifier: CGFloat) {
        self.accentColor = accentColor
        self.fontSizeModifier = fontSizeModifier
    }
}

extension IDScanIDCaptureTheme {
    public init(_ theme: DIVESDKTheme?) {
        if let theme = theme {
            self.init(accentColor: theme.accentColor, fontSizeModifier: theme.fontSizeModifier)
        } else {
            self.init()
        }
    }
}

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
