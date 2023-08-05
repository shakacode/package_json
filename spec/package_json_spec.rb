# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

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

def with_package_json_file(contents = {})
  Dir.mktmpdir("package_json-") do |dir|
    builder = PackageJsonBuilder.new(File.join(dir, "package.json"), contents)

    yield(builder)
  ensure
    builder&.unlink
  end
end

RSpec.describe PackageJson do
  it "has a version number" do
    expect(PackageJson::VERSION).not_to be_nil
  end

  describe "#fetch" do
    it "fetches the value from the package.json" do
      with_package_json_file({ "version" => "1.0.0" }) do |builder|
        package_json = described_class.new(builder.path)

        expect(package_json.fetch("version")).to eq("1.0.0")
      end
    end

    it "reads from disk every time" do
      with_package_json_file({ "version" => "1.0.0" }) do |builder|
        package_json = described_class.new(builder.path)

        expect(package_json.fetch("version")).to eq("1.0.0")

        builder.write({ "version" => "1.1.0" })

        expect(package_json.fetch("version")).to eq("1.1.0")
      end
    end

    context "when the key is not present" do
      it "raises an error" do
        with_package_json_file do |builder|
          package_json = described_class.new(builder.path)

          expect { package_json.fetch("does-not-exist") }.to raise_error(KeyError)
        end
      end

      it "returns the default" do
        with_package_json_file do |builder|
          package_json = described_class.new(builder.path)

          expect(package_json.fetch("does-not-exist", "default")).to eq("default")
        end
      end
    end
  end
end
