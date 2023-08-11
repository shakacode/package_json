# frozen_string_literal: true

require "spec_helper"

RSpec.describe PackageJson do
  around { |example| within_temp_directory { example.run } }

  it "has a version number" do
    expect(PackageJson::VERSION).not_to be_nil
  end

  describe ".new" do
    context "when the package.json does not exist" do
      it "does not error" do
        expect { described_class.new }.not_to raise_error
      end

      it "creates the package.json" do
        described_class.new

        expect(File.exist?("package.json")).to be(true)
      end

      it "defaults to npm as the package manager" do
        package_json = described_class.new

        expect(package_json.manager).to be_a PackageJson::Managers::NpmLike
      end

      it "sets packageManager correctly when no fallback is explicitly provided" do
        described_class.new

        expect(File.exist?("package.json")).to be(true)
        expect(File.read("package.json")).to eq(
          <<~JSON
            {
              "packageManager": "npm"
            }
          JSON
        )
      end

      it "sets packageManager correctly when the package manager is npm" do
        described_class.new(:npm)

        expect(File.exist?("package.json")).to be(true)
        expect(File.read("package.json")).to eq(
          <<~JSON
            {
              "packageManager": "npm"
            }
          JSON
        )
      end

      it "sets packageManager correctly when the package manager is yarn (classic)" do
        described_class.new(:yarn_classic)

        expect(File.exist?("package.json")).to be(true)
        expect(File.read("package.json")).to eq(
          <<~JSON
            {
              "packageManager": "yarn@1"
            }
          JSON
        )
      end

      it "sets packageManager correctly when the package manager is pnpm" do
        described_class.new(:pnpm)

        expect(File.exist?("package.json")).to be(true)
        expect(File.read("package.json")).to eq(
          <<~JSON
            {
              "packageManager": "pnpm"
            }
          JSON
        )
      end

      it "raises an error if the fallback manager is not supported" do
        expect { described_class.new(:unknown) }.to raise_error(
          PackageJson::Error,
          'unsupported package manager "unknown"'
        )
      end
    end

    context "when the package.json already exists with the packageManager property" do
      it "does not error" do
        with_package_json_file({ "version" => "1.0.0" }) do
          expect { described_class.new }.not_to raise_error
        end
      end

      it "uses the packageManager property" do
        with_package_json_file({ "version" => "1.0.0", "packageManager" => "pnpm" }) do
          package_json = described_class.new

          expect(package_json.manager).to be_a PackageJson::Managers::PnpmLike
        end
      end

      it "ignores the fallback manager" do
        with_package_json_file({ "version" => "1.0.0", "packageManager" => "pnpm" }) do
          package_json = described_class.new(:yarn_classic)

          expect(package_json.manager).to be_a PackageJson::Managers::PnpmLike
        end
      end

      it "supports having a version specified" do
        with_package_json_file({ "version" => "1.0.0", "packageManager" => "pnpm@1.2.3" }) do
          package_json = described_class.new

          expect(package_json.manager).to be_a PackageJson::Managers::PnpmLike
        end
      end

      it "requires a major version for yarn" do
        with_package_json_file({ "version" => "1.0.0", "packageManager" => "yarn" }) do
          expect { described_class.new }.to raise_error(PackageJson::Error, "a major version must be present for Yarn")
        end
      end

      it "only supports yarn v1" do
        with_package_json_file({ "version" => "1.0.0", "packageManager" => "yarn@2" }) do
          expect { described_class.new }.to raise_error(PackageJson::Error, "only Yarn classic is supported")
        end
      end

      it "supports a full version being specified for yarn" do
        with_package_json_file({ "version" => "1.0.0", "packageManager" => "yarn@1.2.3" }) do
          package_json = described_class.new

          expect(package_json.manager).to be_a PackageJson::Managers::YarnLike
        end
      end

      it "does not change the packageManager property" do
        with_package_json_file({ "version" => "1.0.0", "packageManager" => "pnpm" }) do
          described_class.new(:yarn_classic)

          expect(File.read("package.json")).to eq(
            <<~JSON
              {
                "version": "1.0.0",
                "packageManager": "pnpm"
              }
            JSON
          )
        end
      end

      it "raises an error if the package manager is not supported" do
        with_package_json_file({ "version" => "1.0.0", "packageManager" => "unknown" }) do
          expect { described_class.new }.to raise_error(
            PackageJson::Error,
            'unsupported package manager "unknown"'
          )
        end
      end
    end

    context "when the package.json already exists without the packageManager property" do
      it "does not error" do
        with_package_json_file({ "version" => "1.0.0" }) do
          expect { described_class.new }.not_to raise_error
        end
      end

      it "uses the fallback manager" do
        with_package_json_file({ "version" => "1.0.0" }) do
          package_json = described_class.new(:yarn_classic)

          expect(package_json.manager).to be_a PackageJson::Managers::YarnLike
        end
      end

      it "does not add the packageManager property" do
        with_package_json_file({ "version" => "1.0.0" }) do
          described_class.new(:yarn_classic)

          expect(File.exist?("package.json")).to be(true)
          expect(File.read("package.json")).to eq(
            <<~JSON
              {
                "version": "1.0.0"
              }
            JSON
          )
        end
      end

      it "raises an error if the fallback manager is not supported" do
        with_package_json_file({ "version" => "1.0.0" }) do
          expect { described_class.new(:unknown) }.to raise_error(
            PackageJson::Error,
            'unsupported package manager "unknown"'
          )
        end
      end
    end
  end

  describe "#fetch" do
    it "fetches the value from the package.json" do
      with_package_json_file({ "version" => "1.0.0" }) do
        package_json = described_class.new

        expect(package_json.fetch("version")).to eq("1.0.0")
      end
    end

    it "reads from disk every time" do
      with_package_json_file({ "version" => "1.0.0" }) do |builder|
        package_json = described_class.new

        expect(package_json.fetch("version")).to eq("1.0.0")

        builder.write({ "version" => "1.1.0" })

        expect(package_json.fetch("version")).to eq("1.1.0")
      end
    end

    context "when the key is not present" do
      it "raises an error" do
        with_package_json_file do
          package_json = described_class.new

          expect { package_json.fetch("does-not-exist") }.to raise_error(KeyError)
        end
      end

      it "returns the default" do
        with_package_json_file do
          package_json = described_class.new

          expect(package_json.fetch("does-not-exist", "default")).to eq("default")
        end
      end
    end
  end

  describe "#merge!" do
    it "passes the parsed contents of the package.json" do
      with_package_json_file({ "version" => "1.0.0" }) do
        package_json = described_class.new

        package_json.merge! do |contents|
          expect(contents).to eq({ "version" => "1.0.0" })

          {}
        end
      end
    end

    it "merges the hash with the existing contents" do
      with_package_json_file({ "version" => "1.0.0" }) do
        package_json = described_class.new

        package_json.merge! { |_| { "name" => "my package" } }

        expect(File.read("package.json")).to eq(
          <<~JSON
            {
              "version": "1.0.0",
              "name": "my package"
            }
          JSON
        )
      end
    end

    it "shallow merges" do
      with_package_json_file({ "version" => "1.0.0", "scripts" => { "test" => "jest" } }) do
        package_json = described_class.new

        package_json.merge! { |_| { "scripts" => { "lint" => "eslint ." } } }

        expect(File.read("package.json")).to eq(
          <<~JSON
            {
              "version": "1.0.0",
              "scripts": {
                "lint": "eslint ."
              }
            }
          JSON
        )
      end
    end

    it "can be used to do deep updates" do
      with_package_json_file({ "version" => "1.0.0", "scripts" => { "test" => "exit 1" } }) do
        package_json = described_class.new

        package_json.merge! do |pj|
          {
            "scripts" => pj.fetch("scripts", {}).merge({
              "lint" => "eslint . --ext js",
              "format" => "prettier --check ."
            })
          }
        end

        expect(File.read("package.json")).to eq(
          <<~JSON
            {
              "version": "1.0.0",
              "scripts": {
                "test": "exit 1",
                "lint": "eslint . --ext js",
                "format": "prettier --check ."
              }
            }
          JSON
        )
      end
    end
  end
end
