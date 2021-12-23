source 'https://code.9ji.com/9ji_APP_iOS/CHCocoaSpec.git'

workspace 'Gobelieve'
platform :ios, '9.0'
use_frameworks!

def allPods
  pod 'FMDB', '2.7.3'
  pod 'opencore-amr/amrnb'
end

target 'Gobelieve' do
  allPods

  target 'GobelieveTests' do
    allPods
  end
end

target 'Example' do
  project 'Example/Example'

  allPods
end
