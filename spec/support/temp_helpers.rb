require "tmpdir"

def within_temp_directory(&block)
  Dir.mktmpdir("package_json-") do |dir|
    Dir.chdir(dir, &block)
  end
end
