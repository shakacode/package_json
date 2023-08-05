# frozen_string_literal: true

require_relative "lib/package_json/version"

Gem::Specification.new do |spec|
  spec.name = "package_json"
  spec.version = PackageJson::VERSION
  spec.authors = ["Gareth Jones"]
  spec.email = %w[open-source@ackama.com]

  spec.summary = "It does stuff"
  spec.description = "It does stuff"
  spec.homepage = "https://github.com/G-Rath/package_json"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  # TODO: we expect to have to disable this if we switch to automatic releases
  #   but until then we've got it enabled to make Rubocop happy
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github .circleci appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
