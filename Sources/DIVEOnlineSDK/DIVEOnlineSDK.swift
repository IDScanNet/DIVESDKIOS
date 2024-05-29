//
//  DIVEOnlineSDK.swift
//  DIVEOnlineSDK
//
//  Created by AKorotkov on 25.10.2022.
//

import UIKit
import IDScanCapture
import DIVESDKCommon
import IDSSystemInfo
import IDSLocationManager

@objc public class DIVEOnlineSDK: NSObject, IDScanIDCaptureDelegate {
    private let baseURL: String
    private let applicantID: String
    private let integrationID: String
    private let token: String
    private var captureSDK: IDScanIDCapture? = nil
    private let locMan = IDSLocationManager()
    private let network = DIVENetwork()
    private let theme: IDScanIDCaptureTheme
    
    @objc private weak var delegate: DIVESDKDelegate?
    
    @objc public var vibroFeedback = true {
        didSet {
            self.captureSDK?.vibroFeedback = self.vibroFeedback
        }
    }
    @objc public var logs = false {
        didSet {
            self.captureSDK?.logs = self.logs
        }
    }
    @objc public var checkForBlur = true {
        didSet {
            self.captureSDK?.checkForBlur = self.checkForBlur
        }
    }
    @objc public var blurTreshold = 0.6 {
        didSet {
            self.captureSDK?.blurTreshold = self.blurTreshold
        }
    }
    
    @objc public var ready: Bool {
        self.captureSDK != nil
    }
    
    @objc public init(applicantID: String, integrationID: String, token: String, baseURL: String, delegate: DIVESDKDelegate, theme: DIVESDKTheme? = nil) {
        self.applicantID = applicantID
        self.integrationID = integrationID
        self.token = token
        self.baseURL = baseURL
        self.delegate = delegate
        self.theme = IDScanIDCaptureTheme(theme)
    }
    
    // MARK: -
    
    @objc public func updateLocation() {
        self.locMan.updateLocation(handler: nil)
    }
    
    @objc public func loadConfiguration(handler block: @escaping (Error?) -> Void) {
        let url = "\(self.baseURL)/Integrations/\(self.integrationID)/Configuration"
        self.network.request(url: url, method: "GET", token: self.token) { result in
            switch result {
                case .success(let resultDic):
                    do {
                        if let jsonString = resultDic["jsonSettings"] as? String,
                           let data = jsonString.data(using: .utf8),
                           let jsonSettings = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                           let capture = IDScanIDCapture(delegate: self, configuration: jsonSettings, theme: self.theme) {
                            self.captureSDK = capture
                            self.captureSDK?.vibroFeedback = self.vibroFeedback
                            self.captureSDK?.logs = self.logs
                            self.captureSDK?.checkForBlur = self.checkForBlur
                            self.captureSDK?.blurTreshold = self.blurTreshold
                            block(nil)
                        } else {
                            block(DIVEError.somethingWentWrong())
                        }
                    } catch {
                        block(DIVEError.somethingWentWrong())
                    }
                case .failure(let error):
                    block(error)
            }
        }
    }
    
    private func sendResult(result: IDScanIDCaptureResult, handler block: @escaping (DIVESDKResult) -> Void, progress progressBlock: @escaping (Float, TimeInterval) -> Void) {
        let url = "\(baseURL)/Validation"
        var params: [String : Any] = ["model" : result.requestParams, "applicantId": self.applicantID]
        params.merge(self.additionalInfoRequestParams) { (_, new) in new }
        self.network.request(url: url, method: "POST", parameters: params, token: self.token, completionHandler: block, progressHandler: progressBlock)
    }
    
    // MARK: -
    
    private var additionalInfoRequestParams: [String : Any] {
        let sysInfo = IDSSystemInfo()
        
        var additionalInfo: [String : Any] = [:]
        
        var deviceMetadata: [String : Any] = [:]
        deviceMetadata["vpnUsage"] = sysInfo.isConnectedToVPN
        deviceMetadata["timeZone"] = sysInfo.currentTimeZone
        deviceMetadata["jailBreak"] = sysInfo.isJailBroken
        if let systemLanguage = sysInfo.systemLanguage {
            deviceMetadata["systemLanguage"] = systemLanguage
        }
        if let appLanguage = sysInfo.appLanguage {
            deviceMetadata["userLanguage"] = appLanguage
        }
        if let moduleVersion = sysInfo.moduleVersion {
            deviceMetadata["clientVersion"] = moduleVersion
        }
        deviceMetadata["clientType"] = sysInfo.platform.lowercased()
        
        additionalInfo["deviceMetadata"] = deviceMetadata
        
        if let location = self.locMan.lastLocation {
            var geolocation: [String : Any] = [:]
            geolocation["latitude"] = location.coordinate.latitude
            geolocation["longitude"] = location.coordinate.longitude
            geolocation["accuracy"] = location.horizontalAccuracy
            
            additionalInfo["geolocation"] = geolocation
        }
        
        var screenInfo: [String : Any] = [:]
        screenInfo["width"] = sysInfo.screenSize.width
        screenInfo["height"] = sysInfo.screenSize.height
        switch sysInfo.deviceOrientation {
            case .portrait:
                screenInfo["orientationType"] = "portrait-primary"
            case .portraitUpsideDown:
                screenInfo["orientationType"] = "portrait-secondary"
            case .landscapeLeft:
                screenInfo["orientationType"] = "landscape-primary"
            case .landscapeRight:
                screenInfo["orientationType"] = "landscape-secondary"
            default: break
        }
        
        additionalInfo["browserMetadata"] = ["screenInfo" : screenInfo]
        
        return additionalInfo
    }
    
    // MARK: -
    
    @objc public func start(from rootVC: UIViewController) {
        guard let captureSDK = self.captureSDK else {
            self.delegate?.diveSDKError(sdk: self, error: DIVEError.configIsNotReady)
            return
        }
        
        captureSDK.start(from: rootVC)
    }
    
    @objc public func close() {
        self.captureSDK?.close()
    }
    
    // MARK: - IDScanIDCaptureDelegate
    
    public func idCaptureResult(sdk: IDScanIDCapture, result: IDScanIDCaptureResult) {
        self.delegate?.diveSDKSendingDataStarted(sdk: self)
        
        self.sendResult(result: result) { [weak self] result in
            guard let strongSelf = self else { return }
            switch result {
                case .success(let data):
                    strongSelf.delegate?.diveSDKResult(sdk: strongSelf, result: data)
                case .failure(let error):
                    strongSelf.delegate?.diveSDKError(sdk: strongSelf, error: error)
            }
        } progress: { [weak self] progress, time in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.diveSDKSendingDataProgress(sdk: strongSelf, progress: progress, requestTime: time)
        }
    }
    
    public func idCaptureError(sdk: IDScanIDCapture, error: Error) {
        self.delegate?.diveSDKError(sdk: self, error: error)
    }
}
