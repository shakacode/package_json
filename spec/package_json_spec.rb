# frozen_string_literal: true

require "spec_helper"

RSpec.describe PackageJson do
  around { |example| within_temp_directory { example.run } }

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

  describe "#mutate" do
    it "passes the parsed contents of the package.json" do
      with_package_json_file({ "version" => "1.0.0" }) do |builder|
        package_json = described_class.new(builder.path)

        package_json.mutate do |contents|
          expect(contents).to eq({ "version" => "1.0.0" })
        end
      end
    end

    it "does nothing with the return value" do
      with_package_json_file({ "version" => "1.0.0" }) do |builder|
        package_json = described_class.new(builder.path)

        package_json.mutate { |_| { "version" => "1.1.0" } }

        expect(File.read(builder.path)).to eq(
          <<~JSON
            {
              "version": "1.0.0"
            }
          JSON
        )
      end
    end

    it "writes back the mutated contents" do
      with_package_json_file({
        "version" => "1.0.0",
        "scripts" => { "test" => "exit 1" }
      }) do |builder|
        package_json = described_class.new(builder.path)

        package_json.mutate do |contents|
          contents["scripts"]["lint"] = "eslint . --ext js,ts"
        end

        expect(File.read(builder.path)).to eq(
          <<~JSON
            {
              "version": "1.0.0",
              "scripts": {
                "test": "exit 1",
                "lint": "eslint . --ext js,ts"
              }
            }
          JSON
        )
      end
    end
  end
end
