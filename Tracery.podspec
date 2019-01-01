Pod::Spec.new do |s|

  s.name         = "Tracery"
  s.version      = "0.0.1"
  s.summary      = "Powerful extensible content generation library inspired by Tracery.io"

  s.description  = <<-DESC
    Tracery is a content generation library originally created by @GalaxyKate; you can find more information at Tracery.io
    This implementation, while heavily inspired by the original, has more features added.
    The content generation in Tracery works based on an input set of rules. The rules determine how content should be generated.
    DESC

  s.homepage     = "https://github.com/BenziAhamed/Tracery"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author    = "Benzi Ahamed"

  s.platforms = { :ios => "8.0", :osx => "10.10" }

  s.source       = { :git => "https://github.com/BenziAhamed/Tracery.git", :tag => "#{s.version}" }
  s.source_files  = "Common"

end