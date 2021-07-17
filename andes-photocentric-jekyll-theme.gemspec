# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "andes-photocentric-jekyll-theme"
  spec.version       = "0.1.0"
  spec.authors       = ["amax"]
  spec.email         = ["anm898989@gmail.com"]

  spec.summary       =  "A photocentric jekyll theme for photographers and travelbloggers"
  spec.homepage      = "https://andrew-max.github.io/tech/2016/01/08/making-the-blog/"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").select { |f| f.match(%r{^(assets|_layouts|_includes|_sass|LICENSE|README)}i) }

  spec.add_runtime_dependency "jekyll", "~> 3.3"

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
end
