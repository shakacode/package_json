# frozen_string_literal: true

require_relative "package_json/managers/base"
require_relative "package_json/managers/npm_like"
require_relative "package_json/managers/pnpm_like"
require_relative "package_json/managers/yarn_like"
require_relative "package_json/version"
require "json"

class PackageJson
  class Error < StandardError; end
  class NotImplementedError < Error; end

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

  # Updates the `package.json` with the result of mutations to the current contents by the passed block
  def mutate
    contents = read_package_json

    yield contents

    write_package_json(contents)
  end

  private

  def read_package_json
    JSON.parse(File.read(path))
  end

  def write_package_json(contents)
    File.write(path, "#{JSON.pretty_generate(contents)}\n")
  end
end
