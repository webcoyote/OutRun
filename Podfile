# Fix: [!] Couldn't determine repo type for URL: `https://cdn.cocoapods.org/`:
#  Connection reset by peer - SSL_connect
# Solution: https://stackoverflow.com/a/73278622
source 'https://github.com/CocoaPods/Specs.git'

project 'OutRun.xcodeproj'

# Uncomment the next line to define a global platform for your project
platform :ios, '15.0'

target 'OutRun' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for OutRun
  pod 'SnapKit', '~> 5.0.0'
  pod 'Charts'
  pod 'CoreStore', '~> 6.3.1'
  pod 'CoreGPX'
  pod 'Cache'
  # pod 'JTAppleCalendar'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end
