Pod::Spec.new do |s|
  s.name             = 'Gobelieve'
  s.version          = '1.1.0'
  s.summary          = 'gobelieve'

  s.description      = <<-DESC
  IM gobelieve组件
                       DESC

  s.homepage         = 'https://code.9ji.com/9ji_APP_iOS/gobelieveSDK'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'minhangwang' => 'archer@9ji.com' }
  s.source           = { :git => 'https://code.9ji.com/9ji_APP_iOS/gobelieveSDK.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.swift_version = "5.3"

  s.source_files = 'Sources/**/*.{h,m,c,swift}'
  s.public_header_files = "Sources/**/*.h"
  
  s.resource = 'Sources/Gobelieve/imKitRes/*.db'
  
  s.static_framework = true
  s.prefix_header_file = false

  s.dependency 'FMDB', '~> 2'
  s.dependency 'GRDB.swift', '~> 5'
  s.dependency 'JiuFoundation', '~> 0.9'
  s.dependency 'opencore-amr/amrnb'
end

