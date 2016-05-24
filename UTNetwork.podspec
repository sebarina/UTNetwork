Pod::Spec.new do |s|
  s.name         = "UTNetwork"
  s.version      = "0.0.1"
  s.summary      = "A short description of UTNetwork."
  s.homepage     = "http://github.com/sebarina/UTNetwork"
  s.license      = "MIT (example)"
  s.author             = { "sebarina xu" => "sebarinaxu@gmail.com" }
  s.ios.deployment_target = "8.0"
  

  s.source       = { :git => "http://EXAMPLE/UTNetwork.git", :tag => "0.0.1" }

  s.source_files  = "Source/**/*"

  s.requires_arc = true

  s.dependency 'AFNetworking', '~> 3.0'

end