# frozen_string_literal: true

require "spec_helper"

RSpec.describe PackageJson do
  around { |example| within_temp_directory { example.run } }

  it "has a version number" do
    expect(PackageJson::VERSION).not_to be_nil
  end

  describe ".read" do
    context "when the package.json does not exist" do
      it "raises an error" do
        expect { described_class.read }.to raise_error(
          PackageJson::Error, "#{Dir.pwd} does not contain a package.json"
        )
      end
    end

    context "when the package.json already exists with the packageManager property" do
      it "does not error" do
        with_package_json_file({ "version" => "1.0.0" }) do
          expect { described_class.read }.not_to raise_error
        end
      end

      it "uses the packageManager property" do
        with_package_json_file({ "version" => "1.0.0", "packageManager" => "pnpm" }) do
          package_json = described_class.read

          expect(package_json.manager).to be_a PackageJson::Managers::PnpmLike
        end
      end

      it "ignores the fallback manager" do
        with_package_json_file({ "version" => "1.0.0", "packageManager" => "pnpm" }) do
          package_json = described_class.read(Dir.pwd, fallback_manager: :yarn_classic)

          expect(package_json.manager).to be_a PackageJson::Managers::PnpmLike
        end
      end

      it "supports having a version specified" do
        with_package_json_file({ "version" => "1.0.0", "packageManager" => "pnpm@1.2.3" }) do
          package_json = described_class.read

          expect(package_json.manager).to be_a PackageJson::Managers::PnpmLike
        end
      end

      it "requires a major version for yarn" do
        with_package_json_file({ "version" => "1.0.0", "packageManager" => "yarn" }) do
          expect { described_class.read }.to raise_error(PackageJson::Error, "a major version must be present for Yarn")
        end
      end

      it "supports yarn classic with version 1.2.3" do
        with_package_json_file({ "version" => "1.0.0", "packageManager" => "yarn@1.2.3" }) do
          package_json = described_class.read

          expect(package_json.manager).to be_a PackageJson::Managers::YarnClassicLike
        end
      end

      it "supports yarn classic with just a major version" do
        with_package_json_file({ "version" => "1.0.0", "packageManager" => "yarn@1" }) do
          package_json = described_class.read

          expect(package_json.manager).to be_a PackageJson::Managers::YarnClassicLike
        end
      end

      it "supports yarn classic with a caret constraint" do
        with_package_json_file({ "version" => "1.0.0", "packageManager" => "yarn@^1.2" }) do
          package_json = described_class.read

          expect(package_json.manager).to be_a PackageJson::Managers::YarnClassicLike
        end
      end

      it "supports yarn classic with tilde constraint" do
        with_package_json_file({ "version" => "1.0.0", "packageManager" => "yarn@~1.2" }) do
          package_json = described_class.read

          expect(package_json.manager).to be_a PackageJson::Managers::YarnClassicLike
        end
      end

      it "doesn't return yarn classic if the major version is 11" do
        with_package_json_file({ "version" => "1.0.0", "packageManager" => "yarn@11.2.3" }) do
          package_json = described_class.read

          expect(package_json.manager).not_to be_a PackageJson::Managers::YarnClassicLike
        end
      end

      it "supports yarn berry with version 2.3.2" do
        with_package_json_file({ "version" => "1.0.0", "packageManager" => "yarn@2.3.2" }) do
          package_json = described_class.read

          expect(package_json.manager).to be_a PackageJson::Managers::YarnBerryLike
        end
      end

      it "returns yarn berry if the major version is ~11.2.3" do
        with_package_json_file({ "version" => "1.0.0", "packageManager" => "yarn@~11.2.3" }) do
          package_json = described_class.read

          expect(package_json.manager).to be_a PackageJson::Managers::YarnBerryLike
        end
      end

      it "does not change the packageManager property" do
        with_package_json_file({ "version" => "1.0.0", "packageManager" => "pnpm" }) do
          described_class.read(Dir.pwd, fallback_manager: :yarn_classic)

          expect_package_json_with_content({ "version" => "1.0.0", "packageManager" => "pnpm" })
        end
      end

      it "raises an error if the package manager is not supported" do
        with_package_json_file({ "version" => "1.0.0", "packageManager" => "unknown" }) do
          expect { described_class.read }.to raise_error(
            PackageJson::Error,
            'unsupported package manager "unknown"'
          )
        end
      end
    end

    context "when the package.json already exists without the packageManager property" do
      it "does not error" do
        with_package_json_file({ "version" => "1.0.0" }) do
          expect { described_class.read }.not_to raise_error
        end
      end

      it "uses the fallback manager" do
        with_package_json_file({ "version" => "1.0.0" }) do
          package_json = described_class.read(Dir.pwd, fallback_manager: :yarn_classic)

          expect(package_json.manager).to be_a PackageJson::Managers::YarnClassicLike
        end
      end

      it "does not add the packageManager property" do
        with_package_json_file({ "version" => "1.0.0" }) do
          described_class.read(Dir.pwd, fallback_manager: :yarn_classic)

          expect_package_json_with_content({ "version" => "1.0.0" })
        end
      end

      it "raises an error if the fallback manager is not supported" do
        with_package_json_file({ "version" => "1.0.0" }) do
          expect { described_class.read(Dir.pwd, fallback_manager: :unknown) }.to raise_error(
            PackageJson::Error,
            'unsupported package manager "unknown"'
          )
        end
      end
    end
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

        expect_package_json_with_content({ "packageManager" => start_with("npm@9.") })
      end

      it "sets packageManager correctly when the package manager is npm" do
        described_class.new(fallback_manager: :npm)

        expect_package_json_with_content({ "packageManager" => start_with("npm@9.") })
      end

      it "sets packageManager correctly when the package manager is yarn (berry)" do
        within_temp_yarn_berry_project(within_example: true) do
          File.unlink("package.json")
          described_class.new(fallback_manager: :yarn_berry)

          expect_package_json_with_content({ "packageManager" => start_with("yarn@3.") })
        end
      end

      it "sets packageManager correctly when the package manager is yarn (classic)" do
        described_class.new(fallback_manager: :yarn_classic)

        expect_package_json_with_content({ "packageManager" => start_with("yarn@1.") })
      end

      it "sets packageManager correctly when the package manager is pnpm" do
        described_class.new(fallback_manager: :pnpm)

        expect_package_json_with_content({ "packageManager" => start_with("pnpm@8.") })
      end

      it "sets packageManager correctly when the package manager is bun" do
        skip_on_windows(pend: true)

        described_class.new(fallback_manager: :bun)

        # :nocov:
        expect_package_json_with_content({ "packageManager" => start_with("bun@1.") })
        # :nocov:
      end

      it "raises an error if the fallback manager is not supported" do
        expect { described_class.new(fallback_manager: :unknown) }.to raise_error(
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
          package_json = described_class.new(fallback_manager: :yarn_classic)

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

      it "supports yarn berry" do
        with_package_json_file({ "version" => "1.0.0", "packageManager" => "yarn@2.3.2" }) do
          package_json = described_class.new

          expect(package_json.manager).to be_a PackageJson::Managers::YarnBerryLike
        end
      end

      it "supports yarn classic" do
        with_package_json_file({ "version" => "1.0.0", "packageManager" => "yarn@1.2.3" }) do
          package_json = described_class.new

          expect(package_json.manager).to be_a PackageJson::Managers::YarnClassicLike
        end
      end

      it "does not change the packageManager property" do
        with_package_json_file({ "version" => "1.0.0", "packageManager" => "pnpm" }) do
          described_class.new(fallback_manager: :yarn_classic)

          expect_package_json_with_content({ "version" => "1.0.0", "packageManager" => "pnpm" })
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
          package_json = described_class.new(fallback_manager: :yarn_classic)

          expect(package_json.manager).to be_a PackageJson::Managers::YarnClassicLike
        end
      end

      it "does not add the packageManager property" do
        with_package_json_file({ "version" => "1.0.0" }) do
          described_class.new(fallback_manager: :yarn_classic)

          expect_package_json_with_content({ "version" => "1.0.0" })
        end
      end

      it "raises an error if the fallback manager is not supported" do
        with_package_json_file({ "version" => "1.0.0" }) do
          expect { described_class.new(fallback_manager: :unknown) }.to raise_error(
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

    context "when the current working directory is changed" do
      it "interacts with the right package.json" do
        with_package_json_file({ "version" => "1.0.0" }) do
          package_json = described_class.new(".")

          within_subdirectory("subdir") do
            expect(package_json.fetch("version")).to eq("1.0.0")
          end
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

        expect_package_json_with_content({
          "version" => "1.0.0",
          "name" => "my package"
        })
      end
    end

    it "shallow merges" do
      with_package_json_file({ "version" => "1.0.0", "scripts" => { "test" => "jest" } }) do
        package_json = described_class.new

        package_json.merge! { |_| { "scripts" => { "lint" => "eslint ." } } }

        expect_package_json_with_content({
          "version" => "1.0.0",
          "scripts" => {
            "lint" => "eslint ."
          }
        })
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

        expect_package_json_with_content({
          "version" => "1.0.0",
          "scripts" => {
            "test" => "exit 1",
            "lint" => "eslint . --ext js",
            "format" => "prettier --check ."
          }
        })
      end
    end

    context "when the current working directory is changed" do
      it "interacts with the right package.json" do
        with_package_json_file({ "version" => "1.0.0" }) do
          package_json = described_class.new(".")

          within_subdirectory("subdir") do
            package_json.merge! { |_| { "scripts" => { "lint" => "eslint ." } } }
          end

          expect_package_json_with_content({
            "version" => "1.0.0",
            "scripts" => {
              "lint" => "eslint ."
            }
          })
        end
      end
    end
  end

  describe "#delete!" do
    it "deletes the key from the package.json" do
      with_package_json_file({ "version" => "1.0.0", "babel" => { "presets" => ["path/to/my/preset"] } }) do
        package_json = described_class.new

        package_json.delete!("babel")

        expect_package_json_with_content({ "version" => "1.0.0" })
      end
    end

    it "returns the value" do
      with_package_json_file({ "version" => "1.0.0", "babel" => { "presets" => ["path/to/my/preset"] } }) do
        package_json = described_class.new

        expect(package_json.delete!("babel")).to eq({ "presets" => ["path/to/my/preset"] })
      end
    end

    context "when the property does not exist" do
      it "does not error" do
        package_json = described_class.new

        expect { package_json.delete!("does not exist") }.not_to raise_error
      end

      it "returns nil" do
        package_json = described_class.new

        expect(package_json.delete!("does not exist")).to be_nil
      end
    end

    context "when the current working directory is changed" do
      it "interacts with the right package.json" do
        with_package_json_file({ "version" => "1.0.0", "babel" => { "presets" => ["path/to/my/preset"] } }) do
          package_json = described_class.new(".")

          within_subdirectory("subdir") do
            package_json.delete!("babel")
          end

          expect_package_json_with_content({ "version" => "1.0.0" })
        end
      end
    end
  end

  describe "#record_package_manager!" do
    it "records the manager and exact version" do
      with_package_json_file({}) do
        package_json = described_class.new(fallback_manager: :pnpm)

        package_json.record_package_manager!

        expect_package_json_with_content({ "packageManager" => start_with("pnpm@8") })
      end
    end

    context "when the packageManager property is already present" do
      it "does not change the manager" do
        with_package_json_file({ "packageManager" => "npm@1.2.3" }) do
          package_json = described_class.new(fallback_manager: :yarn_classic)

          package_json.record_package_manager!

          expect_package_json_with_content({ "packageManager" => start_with("npm@") })
        end
      end

      it "does update the version" do
        with_package_json_file({ "packageManager" => "npm@1.2.3" }) do
          package_json = described_class.new(fallback_manager: :yarn_classic)

          package_json.record_package_manager!

          expect_package_json_with_content({ "packageManager" => start_with("npm@9.") })
        end
      end
    end
  end
end
