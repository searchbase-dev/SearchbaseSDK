Pod::Spec.new do |s|
  s.name         = "SearchbaseSDK"
  s.version      = "0.1.0"
  s.summary      = "A brief description of SearchbaseSDK."
  s.description  = <<-DESC
                   A longer description of SearchbaseSDK.
                   DESC
  s.homepage     = "https://searchbase.dev"
  s.license      = "MIT"
  s.author       = { "Your Name" => "your_email@example.com" }
  s.source       = { :git => "http://EXAMPLE/SearchbaseSDK.git", :tag => "#{s.version}" }
  s.source_files = "SearchbaseSDK/**/*.{h,m,swift}"
  s.swift_version = "5.0"
end