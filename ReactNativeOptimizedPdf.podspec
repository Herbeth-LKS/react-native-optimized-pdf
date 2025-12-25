require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name         = "ReactNativeOptimizedPdf"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.description  = <<-DESC
                  High-performance PDF viewer for React Native
                   DESC
  s.homepage     = "https://github.com/your-username/react-native-optimized-pdf"
  s.license      = "MIT"
  s.author       = { "Your Name" => "your-email@example.com" }
  s.platform     = :ios, "12.0"
  s.source       = { :git => "https://github.com/your-username/react-native-optimized-pdf.git", :tag => "#{s.version}" }
  s.source_files = "ios/*.{swift,h,m}"
  s.requires_arc = true
  s.swift_version = "5.0"
  s.dependency "React-Core"
end