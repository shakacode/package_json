# frozen_string_literal: true

require "spec_helper"

def expect_manager_to_be_invoked_with(args)
  expect(Kernel).to have_received(:system).with(match(/#{package_manager_cmd} #{args}/))
end

RSpec.describe PackageJson::Managers::YarnLike do
  subject(:manager) { described_class.new(package_json, manager_cmd: package_manager_cmd) }

  let(:package_manager_cmd) { "npx yarn@1" }
  let(:package_json) { PackageJson.new }

  around { |example| within_temp_directory { example.run } }

  before do
    allow(Kernel).to receive(:system).and_wrap_original do |original_method, *args|
      # make things quieter by default
      args[0] += " --silent --no-progress"

      original_method.call(*args, 2 => "/dev/null")
    end
  end

  describe "#install" do
    it "runs" do
      with_package_json_file do
        manager.install

        expect_manager_to_be_invoked_with("install")
      end
    end

    context "when passing the usual options" do
      it "supports frozen" do
        with_package_json_file do
          # frozen requires that a lockfile exist
          File.write("yarn.lock", "")

          manager.install(frozen: true)

          expect_manager_to_be_invoked_with("install --frozen-lockfile")
        end
      end

      it "supports ignore_scripts" do
        with_package_json_file do
          manager.install(ignore_scripts: true)

          expect_manager_to_be_invoked_with("install --ignore-scripts")
        end
      end

      it "supports legacy_peer_deps" do
        with_package_json_file do
          manager.install(legacy_peer_deps: true)

          expect_manager_to_be_invoked_with("install")
        end
      end

      it "supports omit_optional_deps" do
        with_package_json_file do
          manager.install(omit_optional_deps: true)

          expect_manager_to_be_invoked_with("install --ignore-optional")
        end
      end

      it "supports all the options together" do
        with_package_json_file do
          # frozen requires that a lockfile exist
          File.write("yarn.lock", "")

          manager.install(
            frozen: true,
            ignore_scripts: true,
            legacy_peer_deps: true,
            omit_optional_deps: true
          )

          expect_manager_to_be_invoked_with("install --frozen-lockfile --ignore-scripts --ignore-optional")
        end
      end
    end
  end

  describe "#add" do
    it "adds dependencies as production by default" do
      with_package_json_file do
        manager.add(["example"])

        expect_manager_to_be_invoked_with("add example")
        expect(File.read("package.json")).to eq(
          <<~JSON
            {
              "dependencies": {
                "example": "^0.0.0"
              }
            }
          JSON
        )
      end
    end

    it "supports adding production dependencies" do
      with_package_json_file do
        manager.add(["example"], type: :production)

        expect_manager_to_be_invoked_with("add example")
        expect(File.read("package.json")).to eq(
          <<~JSON
            {
              "dependencies": {
                "example": "^0.0.0"
              }
            }
          JSON
        )
      end
    end

    it "supports adding dev dependencies" do
      with_package_json_file do
        manager.add(["example"], type: :dev)

        expect_manager_to_be_invoked_with("add --dev example")
        expect(File.read("package.json")).to eq(
          <<~JSON
            {
              "devDependencies": {
                "example": "^0.0.0"
              }
            }
          JSON
        )
      end
    end

    it "supports adding optional dependencies" do
      with_package_json_file do
        manager.add(["example"], type: :optional)

        expect_manager_to_be_invoked_with("add --optional example")
        expect(File.read("package.json")).to eq(
          <<~JSON
            {
              "optionalDependencies": {
                "example": "^0.0.0"
              }
            }
          JSON
        )
      end
    end

    context "when the package manager errors" do
      it "raises an error" do
        expect { manager.add(["does-not-exist"]) }.to raise_error(PackageJson::Error)
      end
    end

    context "when the group type is not supported" do
      it "raises an error" do
        expect { manager.add([], type: :unknown) }.to raise_error(PackageJson::Error)
      end
    end

    context "when passing the usual options" do
      it "supports ignore_scripts" do
        with_package_json_file do
          manager.add(["example"], ignore_scripts: true)

          expect_manager_to_be_invoked_with("add --ignore-scripts example")
        end
      end

      it "supports legacy_peer_deps" do
        with_package_json_file do
          manager.add(["example"], legacy_peer_deps: true)

          expect_manager_to_be_invoked_with("add example")
        end
      end

      it "supports omit_optional_deps" do
        with_package_json_file do
          manager.add(["example"], omit_optional_deps: true)

          expect_manager_to_be_invoked_with("add --ignore-optional example")
        end
      end

      it "supports all the options together" do
        with_package_json_file do
          manager.add(
            ["example"],
            ignore_scripts: true,
            legacy_peer_deps: true,
            omit_optional_deps: true
          )

          expect_manager_to_be_invoked_with("add --ignore-scripts --ignore-optional example")
        end
      end
    end
  end

  describe "#remove" do
    it "removes the package" do
      with_package_json_file({ "dependencies" => { "example" => "^0.0.0", "example2" => "^0.0.0" } }) do
        # yarn requires that a lockfile exist for remove to work
        File.write("yarn.lock", "")

        manager.remove(["example"])

        expect(File.read("package.json")).to eq(
          <<~JSON
            {
              "dependencies": {
                "example2": "^0.0.0"
              }
            }
          JSON
        )
      end
    end

    context "when passing the usual options" do
      it "supports ignore_scripts" do
        with_package_json_file({ "dependencies" => { "example" => "^0.0.0", "example2" => "^0.0.0" } }) do
          # yarn requires that a lockfile exist for remove to work
          File.write("yarn.lock", "")

          manager.remove(["example"], ignore_scripts: true)

          expect_manager_to_be_invoked_with("remove --ignore-scripts example")
        end
      end

      it "supports legacy_peer_deps" do
        with_package_json_file({ "dependencies" => { "example" => "^0.0.0", "example2" => "^0.0.0" } }) do
          # yarn requires that a lockfile exist for remove to work
          File.write("yarn.lock", "")

          manager.remove(["example"], legacy_peer_deps: true)

          expect_manager_to_be_invoked_with("remove example")
        end
      end

      it "supports omit_optional_deps" do
        with_package_json_file({ "dependencies" => { "example" => "^0.0.0", "example2" => "^0.0.0" } }) do
          # yarn requires that a lockfile exist for remove to work
          File.write("yarn.lock", "")

          manager.remove(["example"], omit_optional_deps: true)

          expect_manager_to_be_invoked_with("remove --ignore-optional example")
        end
      end

      it "supports all the options together" do
        with_package_json_file({ "dependencies" => { "example" => "^0.0.0", "example2" => "^0.0.0" } }) do
          # yarn requires that a lockfile exist for remove to work
          File.write("yarn.lock", "")

          manager.remove(
            ["example"],
            ignore_scripts: true,
            legacy_peer_deps: true,
            omit_optional_deps: true
          )

          expect_manager_to_be_invoked_with("remove --ignore-scripts --ignore-optional example")
        end
      end
    end
  end

  describe "#run" do
    before do
      allow(Kernel).to receive(:system).and_wrap_original do |original_method, *args|
        original_method.call(*args, 2 => "/dev/null", 1 => "/dev/null")
      end

      File.write("helper.rb", 'File.write("package_json_run_script_helper.txt", ARGV)')
    end

    it "runs the script" do
      with_package_json_file({ "scripts" => { "rspec-test-helper" => "ruby helper.rb" } }) do
        manager.run("rspec-test-helper")

        expect_manager_to_be_invoked_with("run rspec-test-helper")
        expect(File.read("package_json_run_script_helper.txt")).to eq("[]")
      end
    end

    it "passes args correctly" do
      with_package_json_file({ "scripts" => { "rspec-test-helper" => "ruby helper.rb" } }) do
        manager.run("rspec-test-helper", ["--silent", "--flag", "value"])

        expect_manager_to_be_invoked_with("run rspec-test-helper --silent --flag value")
        expect(File.read("package_json_run_script_helper.txt")).to eq('["--silent", "--flag", "value"]')
      end
    end

    context "when the script is not there" do
      it "raises an error" do
        with_package_json_file do
          expect { manager.run("rspec-test-helper") }.to raise_error(PackageJson::Error)

          expect_manager_to_be_invoked_with("run rspec-test-helper")
        end
      end
    end

    it "supports the silent option" do
      with_package_json_file({ "scripts" => { "rspec-test-helper" => "ruby helper.rb" } }) do
        manager.run("rspec-test-helper", silent: true)

        expect_manager_to_be_invoked_with("run --silent rspec-test-helper")
        expect(File.read("package_json_run_script_helper.txt")).to eq("[]")
      end
    end

    it "supports the silent option with args" do
      with_package_json_file({ "scripts" => { "rspec-test-helper" => "ruby helper.rb" } }) do
        manager.run("rspec-test-helper", ["--silent", "value", "--flag"], silent: true)

        expect_manager_to_be_invoked_with("run --silent rspec-test-helper --silent value --flag")
        expect(File.read("package_json_run_script_helper.txt")).to eq('["--silent", "value", "--flag"]')
      end
    end
  end
end
