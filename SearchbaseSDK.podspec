Pod::Spec.new do |s|
  s.name         = "SearchbaseSDK"
  s.version      = "1.0.0"
  s.summary      = "Swift SDK for Searchbase API."
  s.description  = <<-DESC
  Searchbase is a powerful API for building complex search experience into your Firebase project. This SDK provides a convenient way to interact with the Searchbase API.
                   DESC
  s.homepage     = "https://searchbase.dev"
  s.license      = "MIT"
  s.author       = { "Vanly Co." => "support@searchbase.dev" }
  s.source_files = "SearchbaseSDK/SearchbaseSDK/**/*.swift"
  s.swift_version = "5.0"
  s.ios.deployment_target = '12.0'
  s.osx.deployment_target = '10.13'
  s.source       = { :git => "https://github.com/searchbase-dev/SearchbaseSDK.git", :tag => "#{s.version}" }
end
