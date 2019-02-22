#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'ontology_dart_sdk'
  s.version          = '0.0.1'
  s.summary          = 'Ontology Dart SDK'
  s.description      = <<-DESC
SDK for Ontology blockchain.
                       DESC
  s.homepage         = 'https://github.com/ontio-community/ontology-dart-sdk'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'hsiaosiyuan' => 'hsiaosiyuan0@outlook.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'

  s.ios.deployment_target = '8.0'

  s.prepare_command = <<-CMD
scripts/frameworks/build_all.sh
                      CMD

  s.ios.vendored_frameworks = 'Frameworks/base58.framework', 'Frameworks/gmp.framework', 'Frameworks/openssl.framework', 'Frameworks/scrypt.framework'
end

