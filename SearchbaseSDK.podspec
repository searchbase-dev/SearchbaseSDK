Pod::Spec.new do |s|
  s.name         = "SearchbaseSDK"
  s.version      = "0.1.0"
  s.summary      = "A brief description of SearchbaseSDK."
  s.description  = <<-DESC
                   A longer description of SearchbaseSDK.
                   DESC
  s.homepage     = "https://searchbase.dev"
  s.license      = "MIT"
  s.author       = { "Giulio Colleluori" => "giulio@searchbase.dev" }
  # s.source       = { :git => "https://github.com/searchbase-dev/SearchbaseSDK.git", :tag => "#{s.version}" }
  s.source_files = "SearchbaseSDK/SearchbaseSDK/**/*.swift"
  s.swift_version = "5.0"
  s.ios.deployment_target = '12.0'
  s.osx.deployment_target = '10.13'
  s.source       = { :git => "file:///#{Dir.pwd}" }
end
