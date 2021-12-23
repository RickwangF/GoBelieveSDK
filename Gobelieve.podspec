Pod::Spec.new do |s|
  s.name             = 'Gobelieve'
  s.version          = '1.0.1'
  s.summary          = 'gobelieve'

  s.description      = <<-DESC
  IM gobelieve组件
                       DESC

  s.homepage         = 'https://code.9ji.com/9ji_APP_iOS/gobelieveSDK'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'minhangwang' => 'archer@9ji.com' }
  s.source           = { :git => 'https://code.9ji.com/9ji_APP_iOS/gobelieveSDK.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.source_files = 'Sources/**/*.{h,m,c}'
  s.public_header_files = "Sources/**/*.h"
  
  s.resource = 'Sources/imKitRes/*.db'
  
  s.static_framework = true
  s.prefix_header_file = false

  s.dependency 'FMDB'
  s.dependency 'opencore-amr/amrnb'
end

