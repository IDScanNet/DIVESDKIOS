Pod::Spec.new do |s|
    s.name             = 'DIVE-SDK-iOS'
    s.version          = '1.240307.2'
    s.summary          = 'A short description of DIVE iOS SDK.'
    s.homepage         = 'https://github.com/IDScanNet/DIVE-SDK-iOS'
    s.license          = { :type => 'MIT', :file => 'LICENSE.md' }
    s.author           = { 'free felt' => 'eiros@me.com' }
    s.source           = { :git => 'https://github.com/IDScanNet/DIVE-SDK-iOS', :tag => s.version.to_s }
    s.ios.deployment_target = '12.0'
    s.ios.vendored_frameworks = 'Libs/IDScanCapture.xcframework', 'Libs/IDScanPDFDetector.xcframework', 'Libs/IDScanMRZDetector.xcframework'
    s.swift_version = '5.0'

    s.subspec 'DIVESDK' do |ss|
        ss.ios.deployment_target = '12.0'
        ss.source_files = 'Sources/DIVESDKCommon/**/*', 'Sources/DIVESDK/**/*'
    end

    s.subspec 'DIVEOnlineSDK' do |ss|
        ss.ios.deployment_target = '12.0'
        ss.source_files = 'Sources/DIVESDKCommon/**/*', 'Sources/IDSCommonTools/**/*', 'Sources/IDSLocationManager/**/*', 'Sources/IDSSystemInfo/**/*', 'Sources/DIVEOnlineSDK/**/*'
        ss.dependency 'KeychainSwift', '~> 21.0.0'
    end

  end