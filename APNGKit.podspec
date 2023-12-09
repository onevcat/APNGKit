Pod::Spec.new do |s|

  s.name         = "APNGKit"
  s.version      = "2.2.4"
  s.summary      = "High performance and delightful way to play with APNG format in iOS."

  s.description  = <<-DESC
                    APNGKit is a high performance framework for loading and displaying APNG images in iOS and macOS. It's built with 
                    high-level abstractions and brings a delightful API. Since be that, you will feel at home and joy when using APNGKit to 
                    play with images in APNG format.
                   DESC

  s.homepage     = "https://github.com/onevcat/APNGKit"
  s.screenshots  = "https://user-images.githubusercontent.com/1019875/139824374-c83a0d99-7ef6-4497-b980-ee3e3ad7565e.png"
  
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.authors            = { "onevcat" => "onevcat@gmail.com" }
  s.social_media_url   = "http://twitter.com/onevcat"

  s.ios.deployment_target = "9.0"
  s.osx.deployment_target = "10.12"
  s.tvos.deployment_target = "9.0"

  s.source       = { :git => "https://github.com/onevcat/APNGKit.git", :tag => s.version }
  
  s.source_files  = "Source/**/*.swift"
  s.swift_versions = ["5.3", "5.4", "5.5"]
  s.dependency "Delegate", "~> 1.1"
end
