Pod::Spec.new do |s|
  s.name        = "AndroidDeviceReader"
  s.version     = "1.0.2"
  s.summary     = "A library for reading files from adb."
  s.homepage    = "https://github.com/kelvinjjwong/AndroidDeviceReader"
  s.license     = { :type => "MIT" }
  s.authors     = { "kelvinjjwong" => "kelvinjjwong@outlook.com" }

  s.requires_arc = true
  s.swift_version = "5.0"
  s.osx.deployment_target = "14.0"
  s.source   = { :git => "https://github.com/kelvinjjwong/AndroidDeviceReader.git", :tag => s.version }
  s.source_files = "Sources/AndroidDeviceReader/**/*.swift"
    
  s.dependency 'LoggerFactory', '~> 1.1.1'
  s.dependency 'SharedDeviceLib', '~> 1.0.3'
end
