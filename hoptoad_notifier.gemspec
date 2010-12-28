Gem::Specification.new do |s|
  s.name = %q{hoptoad_notifier}
  s.version = "2.3.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Hop Toad"]
  s.date = %q{2006-12-17}
  s.description = %q{This is the notifier gem for integrating apps with Hoptoad.}
  s.email = %q{hoptoad@hoptoad.com}
  s.files = Dir.glob("**/*")
  s.homepage = %q{}
  s.rdoc_options = ["--charset=UTF-8", "--line-numbers", "--inline-source"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{This is the notifier gem for integrating apps with Hoptoad.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3
  end
end
