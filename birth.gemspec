# frozen_string_literal: true

version = File.read(File.expand_path('VERSION', __dir__)).strip

Gem::Specification.new 'birth', version do |g|
  g.summary     = 'Simple markdown to static html site generator and web server'
  g.description = 'Simple framework for markdown based sites'
  g.authors     = ['Rawley Fowler']
  g.email       = 'rawleyfowler@gmail.com'
  g.files       = Dir['README.md', 'lib/**/**']
  g.homepage    = 'https://git.rawley.xyz/?p=rf/birth;a=summary'
  g.license     = 'ISC'

  g.required_ruby_version = '>= 2.6.0'

  g.add_dependency 'optparse'
end
