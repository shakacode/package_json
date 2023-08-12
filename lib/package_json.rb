# frozen_string_literal: true

require_relative "package_json/managers/base"
require_relative "package_json/managers/npm_like"
require_relative "package_json/managers/pnpm_like"
require_relative "package_json/managers/yarn_classic_like"
require_relative "package_json/version"
require "json"

class PackageJson
  class Error < StandardError; end

  class NotImplementedError < Error; end

  attr_reader :manager, :path

  def self.read(path_to_directory = Dir.pwd, fallback_manager = :npm)
    unless File.exist?("#{path_to_directory}/package.json")
      raise Error, "#{path_to_directory} does not contain a package.json"
    end

    new(fallback_manager, path_to_directory)
  end

  def initialize(fallback_manager = :npm, path_to_directory = Dir.pwd)
    @path = path_to_directory

    ensure_package_json_exists(fallback_manager)

    @manager = new_package_manager(determine_package_manager(fallback_manager))
  end

  def determine_package_manager(fallback_manager)
    package_manager = fetch("packageManager", nil)

    return fallback_manager if package_manager.nil?

    name, version = package_manager.split("@")

    if name == "yarn"
      raise Error, "a major version must be present for Yarn" if version.nil? || version.empty?
      raise Error, "only Yarn classic is supported" unless version.start_with?("1")

      return :yarn_classic
    end

    name.to_sym
  end

  def new_package_manager(package_manager_name)
    case package_manager_name
    when :npm
      PackageJson::Managers::NpmLike.new(self)
    when :yarn_classic
      PackageJson::Managers::YarnClassicLike.new(self)
    when :pnpm
      PackageJson::Managers::PnpmLike.new(self)
    else
      raise Error, "unsupported package manager \"#{package_manager_name}\""
    end
  end

  def fetch(key, default = (no_default_set_by_user = true; nil))
    contents = read_package_json

    if no_default_set_by_user
      contents.fetch(key)
    else
      contents.fetch(key, default)
    end
  end

  # Merges the hash returned by the passed block into the existing content of the `package.json`
  def merge!
    pj = read_package_json

    write_package_json(pj.merge(yield read_package_json))
  end

  private

  def package_json_path
    "#{path}/package.json"
  end

  def ensure_package_json_exists(package_manager)
    return if File.exist?(package_json_path)

    pm = package_manager.to_s
    pm = "yarn@1" if package_manager == :yarn_classic

    write_package_json({ "packageManager" => pm })
  end

  def read_package_json
    JSON.parse(File.read(package_json_path))
  end

  def write_package_json(contents)
    File.write(package_json_path, "#{JSON.pretty_generate(contents)}\n")
  end
end
