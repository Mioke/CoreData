#
# Be sure to run `pod lib lint CoreDataStack.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'CoreData'
  s.version          = '0.1.0'
  s.summary          = 'Easy use of Apple CoreData.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/mioke/CoreData'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'KelanJiang' => 'mioke0428@gmail.com' }
  s.source           = { :git => 'https://github.com/mioke/CoreData.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '13.0'
  
  s.default_subspecs = 'Core'

  s.subspec 'Core' do |ss|
    ss.source_files = 'CoreDataStack/Classes/**/*'
  end
  
  s.subspec 'Reactive' do |ss|
    ss.source_files = 'CoreDataStack/Reactive/**/*'
    ss.dependency 'CoreDataStack/Core'
    ss.dependency 'ReactiveSwift'
  end
  
  # s.resource_bundles = {
  #   'CoreDataStack' => ['CoreDataStack/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
end
