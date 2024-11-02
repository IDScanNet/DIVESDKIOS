//
//  DIVESDK.swift
//  DIVESDK
//
//  Created by AKorotkov on 20.12.2022.
//

import UIKit
import IDScanCapture
import DIVESDKCommon

@objc public class DIVESDK: NSObject, IDIVESDK, IDScanIDCaptureDelegate {
    private var baseURL = "https://dive.idscan.net/api/v3"
    private let token: String
    private var captureSDK: IDScanIDCapture? = nil
    private let network = DIVENetwork()
    
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
    
    @objc public var ready: Bool {
        self.captureSDK != nil
    }
    
    @objc public init?(configuration: [String : Any], token: String, baseURL: String? = nil, delegate: DIVESDKDelegate, theme: DIVESDKTheme? = nil) {
        self.token = token
        if let baseURL = baseURL {
            self.baseURL = baseURL
        }
        self.delegate = delegate
        super.init()
        self.captureSDK = IDScanIDCapture(delegate: self, configuration: configuration, theme: IDScanIDCaptureTheme(theme))
        self.captureSDK?.vibroFeedback = self.vibroFeedback
        self.captureSDK?.logs = self.logs
    }
    
    // MARK: -
    
    @objc public func start(from rootVC: UIViewController) {
        self.start(from: rootVC, contentInset: nil)
    }
    
    public func start(from rootVC: UIViewController, contentInset: UIEdgeInsets?) {
        guard let captureSDK = self.captureSDK else {
            self.delegate?.diveSDKError(sdk: self, error: DIVEError.configIsNotReady)
            return
        }
        
        captureSDK.start(from: rootVC, contentInset: contentInset)
    }
    
    @objc public func sendData(data: DIVESDKData) {
        let url = "\(baseURL)/" + (self.token.hasPrefix("sk") ? "Verify" : "Request")
        self.network.request(url: url, method: "POST", parameters: data.requestParams, token: self.token, completionHandler: { [weak self] result in
            guard let strongSelf = self else { return }
            switch result {
                case .success(let data):
                    strongSelf.delegate?.diveSDKResult(sdk: strongSelf, result: data)
                case .failure(let error):
                    strongSelf.delegate?.diveSDKError(sdk: strongSelf, error: error)
            }
        }, progressHandler: { [weak self] progress, time in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.diveSDKSendingDataProgress(sdk: strongSelf, progress: progress, requestTime: time)
        })
    }
    
    @objc public func close() {
        self.captureSDK?.close()
    }
    
    // MARK: - IDScanIDCaptureDelegate
    
    public func idCaptureResult(sdk: IDScanIDCapture, result: IDScanIDCaptureResult) {
        let data = DIVESDKData(frontImage: result.frontImage, backImage: result.backImage, faceImage: result.faceImage, trackString: result.trackString, documentType: result.documentType, realFaceMode: result.realFaceMode)
        self.delegate?.diveSDKDataPrepaired(sdk: self, data: data)
    }
    
    public func idCaptureError(sdk: IDScanIDCapture, error: Error) {
        self.delegate?.diveSDKError(sdk: self, error: error)
    }
}
