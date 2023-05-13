Pod::Spec.new do |s|
  s.name     = 'TOReachability'
  s.version  = '1.0.1'
  s.license  =  { :type => 'MIT', :file => 'LICENSE' }
  s.summary  = 'A lightweight, unit-tested class to detect network changes on iOS'
  s.homepage = 'https://github.com/TimOliver/TOReachability'
  s.author   = 'Tim Oliver'
  s.source   = { :git => 'https://github.com/TimOliver/TOReachability.git', :tag => s.version }
  s.source_files = 'TOReachability/**/*.{h,m}'
  s.requires_arc = true
  s.ios.deployment_target   = '11.0'
  s.osx.deployment_target   = '10.13'
  s.tvos.deployment_target  = '11.0'
end
