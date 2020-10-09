# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'stall/kurone_koyamato/version'

Gem::Specification.new do |spec|
  spec.name          = 'stall-kurone_koyamato'
  spec.version       = Stall::KuroneKoyamato::VERSION
  spec.authors       = ['Kinoba']
  spec.email         = ['tribe@kinoba.fr']

  spec.summary       = 'Stall e-commerce Kurone Koyamato payment gateway integration'
  spec.description   = 'Allows easy Kurone Koyamato gateway integration in a Stall e-commerce app'
  spec.homepage      = 'https://github.com/kinoba/stall-kurone-koyamato'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.5.7'

  spec.add_dependency 'stall', '~> 0.3'

  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop'
end
