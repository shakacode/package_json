require "tmpdir"

def within_temp_directory(&block)
  Dir.mktmpdir("package_json-") do |dir|
    Dir.chdir(dir, &block)
  end
end

def with_package_json_file(contents = {})
  builder = PackageJsonBuilder.new("package.json", contents)

  yield(builder)
ensure
  # :nocov:
  builder&.unlink
  # :nocov:
end
