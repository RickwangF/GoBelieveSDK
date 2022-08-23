#
# Be sure to run `pod lib lint CHMessageSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Gobelieve'
  s.version          = '1.0.6'
  s.summary          = 'gobelieve'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  IM gobelieve组件
                       DESC

  s.homepage         = 'https://code.9ji.com/9ji_APP_iOS/gobelieveSDK'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'minhangwang' => 'archer@9ji.com' }
  s.source           = { :git => 'https://code.9ji.com/9ji_APP_iOS/gobelieveSDK.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'Sources/**/*.{h,m,c}'
  s.public_header_files = "Sources/**/*.h"
  
  s.resource = 'Sources/imKitRes/*.db'
  
  s.static_framework = true

  s.dependency 'FMDB'
  s.dependency 'opencore-amr/amrnb'
end
