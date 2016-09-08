# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fancy_gets/version'

Gem::Specification.new do |spec|
  spec.name          = "fancy_gets"
  spec.version       = FancyGets::VERSION
  spec.authors       = ["Lorin Thwaits"]
  spec.email         = ["lorint@gmail.com"]

  spec.summary       = %q{Enhanced gets with listbox, auto-complete, and password support}
  spec.description   = %q{This gem exists to banish crusty UX that our users endure at the command line.

For far too long we've been stuck with just gets and getc.  When prompting the
user with a list of choices, wouldn't it be nice to have the feel of a <select>
in HTML?  Or to auto-suggest options as they type?  Or perhaps offer a password
entry with asterisks instead of just sitting silent, which confuses many users?

It's all here.  Enjoy!}
  spec.homepage      = "http://polangeles.com/gems/fancy_gets"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
