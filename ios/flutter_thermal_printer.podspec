#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_printlink.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_printlink'
  s.version          = '1.0.0'
  s.summary          = 'A comprehensive Flutter plugin for thermal printer integration'
  s.description      = <<-DESC
A comprehensive Flutter plugin for thermal printer integration with AutoReplyPrint library. 
Supports Bluetooth Classic, Bluetooth LE, USB, and Network connections with label and POS printing modes.
Features include QR codes, barcodes, image printing, and real-time status monitoring.
                       DESC
  s.homepage         = 'https://github.com/Shehzaan-Mansuri/flutter_printlink'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Flutter Thermal Printer' => 'shehzaanmansuri1@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '11.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # External Dependencies for thermal printing (if available)
  # s.dependency 'ExternalPrinterSDK', '~> 1.0'
end
