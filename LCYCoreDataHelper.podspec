Pod::Spec.new do |s|
  s.name = 'LCYCoreDataHelper'
  s.version = '5.1.1'
  s.license = 'MIT'
  s.summary = 'A pure light weight core data framework written in Swift'
  s.homepage = 'https://github.com/leacode/LCYCoreDataHelper'
  s.authors = 'Leacode'
  s.source = { :git => 'https://github.com/leacode/LCYCoreDataHelper.git', :tag => s.version }

  s.ios.deployment_target = '8.0'

  s.source_files = 'LCYCoreDataHelper/LCYCoreDataHelper/*.{h,swift}'
end
