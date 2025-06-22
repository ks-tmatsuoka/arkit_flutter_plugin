#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint arkit_plugin.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'arkit_plugin'
  s.version          = '0.0.1'
  s.summary          = 'A new flutter plugin project.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*.{h,m,mm,swift}'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'GLTFSceneKit'
  s.platform = :ios, '14.0'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES', 
    'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64',
    'SWIFT_OBJC_BRIDGING_HEADER' => '$(PODS_TARGET_SRCROOT)/Classes/arkit_plugin-Bridging-Header.h'
  }
  s.swift_version = '5.0'
end
