#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint ar_flutter_plugin.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'ar_flutter_plugin'
  s.version          = '0.6.2'
  s.summary          = 'A Flutter plugin for shared AR experiences.'
  s.description      = <<-DESC
A Flutter plugin for shared AR experiences supporting Android and iOS.
                       DESC
  s.homepage         = 'https://lars.carius.io'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Lars Carius' => 'carius.lars@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'GLTFSceneKit'
  s.dependency 'SwiftJWT'
  s.static_framework = true
  #s.dependency 'ARCore/CloudAnchors', '~> 1.12.0'
  #s.dependency 'ARCore', '~> 1.2.0'
  s.dependency 'ARCore/CloudAnchors', '~> 1.33.0' # Updated from 1.32 to 1.33 to support Apple Silicon, info here: https://github.com/google-ar/arcore-ios-sdk/issues/59#issuecomment-1219756010
  s.platform = :ios, '13.0'


  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
