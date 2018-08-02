Pod::Spec.new do |spec|
  spec.name          = 'Laurine'
  spec.version       = '0.2.2'
  spec.license       = { :type => 'MIT', :file => 'LICENSE' }
  spec.homepage      = 'https://github.com/JiriTrecak/Laurine'
  spec.authors       = { 'Jiří Třečák' => 'jiritrecak@gmail.com' }
  spec.summary       = 'Localization code generator written (with love) for Swift, intended to end the constant problems that localizations present developers.'
  spec.source        = { :git => 'https://github.com/JiriTrecak/Laurine.git', :tag => '0.2.2' }
  spec.resources     = 'LaurineGenerator.swift'
end