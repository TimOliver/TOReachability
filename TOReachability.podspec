Pod::Spec.new do |s|
  s.name     = 'TOReachability'
  s.version  = '0.0.1'
  s.license  =  { :type => 'MIT', :file => 'LICENSE' }
  s.summary  = 'A lightweight, unit-tested class to detect network changes on iOS'
  s.homepage = 'https://github.com/TimOliver/TOReachability'
  s.author   = 'Tim Oliver'
  s.source   = { :git => 'https://github.com/TimOliver/TOReachability.git', :tag => s.version }
  s.platform = :ios, '8.0'
  s.source_files = 'TOReachability/**/*.{h,m}'
  s.requires_arc = true
end
