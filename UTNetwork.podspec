Pod::Spec.new do |s|
  s.name         = "UTNetwork"
  s.version      = "1.0.0"
  s.summary      = "Network request library based on AFNetworking"
  s.homepage     = "http://github.com/sebarina/UTNetwork"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "sebarina xu" => "sebarinaxu@gmail.com" }
  s.ios.deployment_target = "8.0"
  

  s.source       = { :git => "https://github.com/sebarina/UTNetwork.git", :tag => "1.0.0" }

  s.source_files  = "Source/**/*"

  s.requires_arc = true

  s.dependency 'AFNetworking', '~> 3.0'

end
