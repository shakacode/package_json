class PackageJsonBuilder
  # @return [String]
  attr_reader :path

  def initialize(path, contents)
    @path = path
    write(contents)
  end

  def write(contents)
    File.write(path, "#{JSON.pretty_generate(contents)}\n")
  end

  def unlink
    File.unlink(path)
  end
end
