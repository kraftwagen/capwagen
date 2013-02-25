lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
require 'capwagen/version'

Gem::Specification.new do |spec|
  spec.name         = 'capwagen'
  spec.version      = Capwagen::VERSION
  spec.platform     = Gem::Platform::RUBY
  spec.description  = <<-DESC
    Capistrano is an open source tool for running scripts on multiple servers. It’s primary use is for easily deploying applications. While it was built specifically for deploying Rails apps, it’s pretty simple to customize it to deploy other types of applications. This package is a deployment "recipe" to work with Kraftwagen/Drupal applications.
  DESC
  spec.summary      = <<-DESC.strip.gsub(/\n\s+/, " ")
    Deploying Kraftwagen/Drupal applications with Capistrano.
  DESC

  spec.files        = Dir.glob("{bin,lib}/**/*") + %w(README.md LICENSE.md)
  spec.require_path = 'lib'
  spec.has_rdoc     = false

  spec.bindir       = "bin"
  spec.executables << "capwagen"

  spec.add_dependency 'capistrano', "~> 2.14.2"

  spec.authors      = [ "Rolf van de Krol" ]
  spec.email        = [ "info AT rolfvandekrol DOT com" ]
  spec.homepage     = "http://github.com/kraftwagen/capwagen"
  spec.rubyforge_project = "capwagen"
end