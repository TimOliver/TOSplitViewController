Pod::Spec.new do |s|
  s.name     = 'TOSplitViewController'
  s.version  = '0.0.4'
  s.license  =  { :type => 'MIT', :file => 'LICENSE' }
  s.summary  = 'A split view controller that allows up to 3 columns.'
  s.homepage = 'https://github.com/TimOliver/TOSplitViewController'
  s.author   = 'Tim Oliver'
  s.source   = { :git => 'https://github.com/TimOliver/TOSplitViewController.git', :tag => s.version }
  s.platform = :ios, '8.0'
  s.source_files = 'TOSplitViewController/**/*.{h,m}'
  s.requires_arc = true
end
