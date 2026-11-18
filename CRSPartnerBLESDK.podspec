Pod::Spec.new do |s|
  s.name = 'CRSPartnerBLESDK'
  s.version = '0.1.5'
  s.summary = 'COROS Partner BLE SDK for iOS.'
  s.description = 'COROS Partner BLE SDK for iOS authorization and heart rate broadcast integration.'
  s.homepage = 'https://github.com/coroslab/CRSPartnerBLESDK-iOS'
  s.license = { :type => 'Proprietary' }
  s.author = { 'COROS' => 'ios@coros.com' }
  s.platform = :ios, '14.0'
  s.swift_version = '5.9'
  s.source = { :git => 'https://github.com/coroslab/CRSPartnerBLESDK-iOS.git', :tag => s.version.to_s }
  s.vendored_frameworks = 'Frameworks/CRSPartnerBLESDK.xcframework'
end
