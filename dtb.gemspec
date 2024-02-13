# frozen_string_literal: true

require_relative "lib/dtb/version"

Gem::Specification.new do |spec|
  spec.name = "dtb"
  spec.version = DTB::VERSION
  spec.authors = ["Nicolas Sanguinetti"]
  spec.email = ["foca@foca.io"]

  spec.summary = "Toolkit for building dynamic data tables in Rails"
  spec.description = <<~DESC
    DataTable Builder provides simple building blocks to build complex
    filterable queries and turn them into easy to render datatables using
    Rails.
  DESC
  spec.homepage = "https://github.com/foca/dtb"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 4.2", "< 8.0"
  spec.add_dependency "activemodel", ">= 4.2", "< 8.0"
  spec.add_dependency "railties", ">= 4.2", "< 8.0"
  spec.add_dependency "rack"
  spec.add_dependency "i18n"
end
