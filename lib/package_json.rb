# frozen_string_literal: true

require_relative "package_json/version"
require "json"

class PackageJson
  attr_reader :path

  def initialize(path_to_package_json)
    @path = path_to_package_json
  end

  def fetch(key, default = (no_default_set_by_user = true; nil))
    contents = read_package_json

    if no_default_set_by_user
      contents.fetch(key)
    else
      contents.fetch(key, default)
    end
  end

  private

  def read_package_json
    JSON.parse(File.read(path))
  end
end
