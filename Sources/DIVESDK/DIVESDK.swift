//
//  DIVESDK.swift
//  DIVESDK
//
//  Created by AKorotkov on 20.12.2022.
//

import UIKit
import IDScanCapture
import DIVESDKCommon

@objc public class DIVESDK: NSObject, IDScanIDCaptureDelegate {
    private let baseURL = "https://dvs2.idware.net/api/v3"
    private let token: String
    private var captureSDK: IDScanIDCapture? = nil
    
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
    
    @objc public init?(configuration: [String : Any], token: String, delegate: DIVESDKDelegate) {
        guard CaptureConfiguration(json: configuration) != nil else { return nil }
        
        self.token = token
        self.delegate = delegate
        super.init()
        self.captureSDK = IDScanIDCapture(delegate: self, configuration: configuration)
        self.captureSDK?.vibroFeedback = self.vibroFeedback
        self.captureSDK?.logs = self.logs
        self.captureSDK?.checkForBlur = self.checkForBlur
        self.captureSDK?.blurTreshold = self.blurTreshold
    }
    
    // MARK: -
    
    private func sendResult(result: IDScanIDCaptureResult, handler block: @escaping (DIVESDKResult) -> Void, progress progressBlock: @escaping (Float, TimeInterval) -> Void) {
        let url = "\(baseURL)/Verify"
        DIVENetwork.request(url: url, method: .post, parameters: result.requestParams, token: self.token, completionHandler: block, progressHandler: progressBlock)
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
