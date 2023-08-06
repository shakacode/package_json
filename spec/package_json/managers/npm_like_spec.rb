# frozen_string_literal: true

require "spec_helper"

RSpec.describe PackageJson::Managers::NpmLike do
  subject(:manager) { described_class.new(package_manager_cmd, package_json) }

  let(:package_manager_cmd) { "npx npm@9" }
  let(:package_json) { PackageJson.new("package.json") }

  around { |example| within_temp_directory { example.run } }

  before do
    # make things quieter by default
    ENV["NPM_CONFIG_LOGLEVEL"] = "silent"
    ENV["NPM_CONFIG_PROGRESS"] = "false"
    # make things a bit faster by skipping node_modules
    ENV["NPM_CONFIG_PACKAGE_LOCK_ONLY"] = "true"

    allow(Kernel).to receive(:system).and_call_original
  end

  describe "#install" do
    it "runs" do
      with_package_json_file do
        manager.install

        expect(Kernel).to have_received(:system).with(match(/#{package_manager_cmd} install/))
      end
    end
  end

  describe "#add_and_install" do
    it "adds dependencies as production by default" do
      manager.add_and_install(["example"])

      expect(Kernel).to have_received(:system).with(match(/#{package_manager_cmd} install --save-prod example/))
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

    it "supports adding production dependencies" do
      manager.add_and_install(["example"], :production)

      expect(Kernel).to have_received(:system).with(match(/#{package_manager_cmd} install --save-prod example/))
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

    it "supports adding dev dependencies" do
      manager.add_and_install(["example"], :dev)

      expect(Kernel).to have_received(:system).with(match(/#{package_manager_cmd} install --save-dev example/))
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

    it "supports adding optional dependencies" do
      manager.add_and_install(["example"], :optional)

      expect(Kernel).to have_received(:system).with(match(/#{package_manager_cmd} install --save-optional example/))
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

    context "when the package manager errors" do
      it "raises an error" do
        expect { manager.add_and_install(["does-not-exist"]) }.to raise_error(PackageJson::Error)
      end
    end

    context "when the group type is not supported" do
      it "raises an error" do
        expect { manager.add_and_install([], :unknown) }.to raise_error(PackageJson::Error)
      end
    end
  end

  describe "#remove" do
    it "removes the package" do
      with_package_json_file({ "dependencies" => { "example" => "^0.0.0", "example2" => "^0.0.0" } }) do
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
  end
end
