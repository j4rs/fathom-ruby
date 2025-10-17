# frozen_string_literal: true

require_relative "lib/fathom/version"

Gem::Specification.new do |spec|
  spec.name = "fathom-ruby"
  spec.version = Fathom::VERSION
  spec.authors = ["Jorge Rodriguez"]

  spec.summary = "Ruby library for the Fathom API"
  spec.description = "A comprehensive Ruby gem for interacting with the Fathom API, supporting meetings, \
                      recordings, teams, webhooks, and more."
  spec.homepage = "https://github.com/j4rs/fathom-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies - none! Using only Ruby stdlib
  # Development dependencies are specified in Gemfile
end
