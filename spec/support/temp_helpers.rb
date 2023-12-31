require "tmpdir"

def within_temp_directory(tmpdir = nil, &block)
  Dir.mktmpdir("package_json-", tmpdir) do |dir|
    Dir.chdir(dir, &block)
  end
end

def within_subdirectory(dir, &block)
  Dir.mkdir(dir)
  Dir.chdir(dir, &block)
end

def with_package_json_file(contents = {})
  builder = PackageJsonBuilder.new("package.json", contents)

  yield(builder)
ensure
  # :nocov:
  builder&.unlink
  # :nocov:
end
