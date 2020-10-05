 # coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'stall/cmcic/version'

Gem::Specification.new do |spec|
  spec.name          = 'stall-cmcic'
  spec.version       = Stall::Cmcic::VERSION
  spec.authors       = ['vala']
  spec.email         = ['vala@glyph.fr']

  spec.summary       = %q{Stall e-commerce CM-CIC payment gateway integration}
  spec.description   = %q{Allows easy CM-CIC gateway integration in a Stall e-commerce app}
  spec.homepage      = 'https://github.com/rails-stall/stall-cmcic'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'stall', '~> 0.3'
  spec.add_dependency 'cic_payment', '~> 0.4'

  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
