# frozen_string_literal: true

require "spec_helper"

RSpec.describe PackageJson::Managers::YarnClassicLike do
  subject(:manager) { described_class.new(package_json) }

  let(:package_manager_binary) { "yarn" }
  let(:package_json) { instance_double(PackageJson, directory: Dir.pwd) }

  around { |example| within_temp_directory { example.run } }

  describe "#version" do
    it "returns the version" do
      expect(manager.version).to start_with("1.22")
    end
  end

  describe "#install" do
    it "runs and returns true" do
      with_package_json_file do
        result = manager.install

        expect(result).to be(true)
        expect_manager_to_be_invoked_with("install")
      end
    end

    it "supports frozen" do
      with_package_json_file do
        # frozen requires that a lockfile exist
        File.write("yarn.lock", "")

        result = manager.install(frozen: true)

        expect(result).to be(true)
        expect_manager_to_be_invoked_with("install --frozen-lockfile")
      end
    end

    context "when there is an error" do
      it "returns false" do
        manager # ensure the package.json is valid when the manager is created

        File.write("package.json", "{},")

        expect(manager.install).to be(false)
      end
    end

    context "when the current working directory is changed" do
      it "interacts with the right package.json" do
        with_package_json_file do
          manager # initialize the package.json in the current directory

          within_subdirectory("subdir") do
            File.write("package.json", "{},")

            expect(manager.install).to be(true)
          end
        end
      end
    end
  end

  describe "#install!" do
    it "runs and returns nil" do
      with_package_json_file do
        expect(manager.install!).to be_nil
      end
    end

    context "when there is an error" do
      it "raises an error" do
        manager # ensure the package.json is valid when the manager is created

        File.write("package.json", "{},")

        expect { manager.install! }.to raise_error(PackageJson::Error)
      end
    end
  end

  describe "#native_install_command" do
    it "returns the full command" do
      expect(manager.native_install_command).to eq([package_manager_binary, "install"])
    end

    it "supports frozen" do
      expect(manager.native_install_command(frozen: true)).to eq(
        [package_manager_binary, "install", "--frozen-lockfile"]
      )
    end
  end

  describe "#add" do
    it "adds dependencies as production by default" do
      with_package_json_file do
        result = manager.add(["example"])

        expect(result).to be(true)
        expect_manager_to_be_invoked_with("add example")
        expect_package_json_with_content({
          "dependencies" => {
            "example" => "^0.0.0"
          }
        })
      end
    end

    it "supports adding production dependencies" do
      with_package_json_file do
        result = manager.add(["example"], type: :production)

        expect(result).to be(true)
        expect_manager_to_be_invoked_with("add example")
        expect_package_json_with_content({
          "dependencies" => {
            "example" => "^0.0.0"
          }
        })
      end
    end

    it "supports adding dev dependencies" do
      with_package_json_file do
        result = manager.add(["example"], type: :dev)

        expect(result).to be(true)
        expect_manager_to_be_invoked_with("add --dev example")
        expect_package_json_with_content({
          "devDependencies" => {
            "example" => "^0.0.0"
          }
        })
      end
    end

    it "supports adding optional dependencies" do
      with_package_json_file do
        result = manager.add(["example"], type: :optional)

        expect(result).to be(true)
        expect_manager_to_be_invoked_with("add --optional example")
        expect_package_json_with_content({
          "optionalDependencies" => {
            "example" => "^0.0.0"
          }
        })
      end
    end

    it "supports adding dependencies with exact version" do
      with_package_json_file do
        result = manager.add(["example"], exact: true)

        expect(result).to be(true)
        expect_manager_to_be_invoked_with("add --exact example")
        expect_package_json_with_content({
          "dependencies" => {
            "example" => "0.0.0"
          }
        })
      end
    end

    it "supports adding dev dependencies with exact version" do
      with_package_json_file do
        result = manager.add(["example"], type: :dev, exact: true)

        expect(result).to be(true)
        expect_manager_to_be_invoked_with("add --dev --exact example")
        expect_package_json_with_content({
          "devDependencies" => {
            "example" => "0.0.0"
          }
        })
      end
    end

    it "supports adding multiple packages with exact version" do
      with_package_json_file do
        result = manager.add(%w[example example2], exact: true)

        expect(result).to be(true)
        expect_manager_to_be_invoked_with("add --exact example example2")
        expect_package_json_with_content({
          "dependencies" => {
            "example" => "0.0.0",
            "example2" => "0.0.0"
          }
        })
      end
    end

    context "when the group type is not supported" do
      it "raises an error" do
        expect { manager.add([], type: :unknown) }.to raise_error(PackageJson::Error)
      end
    end

    context "when the package manager errors" do
      it "returns false" do
        expect(manager.add(["does-not-exist"])).to be(false)
      end
    end

    context "when the current working directory is changed" do
      it "interacts with the right package.json" do
        manager # initialize the package.json in the current directory

        within_subdirectory("subdir") do
          File.write("package.json", "{},")

          expect(manager.add(["example"])).to be(true)
        end
      end
    end
  end

  describe "#add!" do
    it "returns nil" do
      with_package_json_file do
        expect(manager.add!(["example"])).to be_nil
      end
    end

    context "when the package manager errors" do
      it "raises an error" do
        expect { manager.add!(["does-not-exist"]) }.to raise_error(PackageJson::Error)
      end
    end
  end

  describe "#remove" do
    before do
      # yarn requires that a lockfile exist for remove to work
      File.write("yarn.lock", "")
    end

    it "removes the package and returns true" do
      with_package_json_file({ "dependencies" => { "example" => "^0.0.0", "example2" => "^0.0.0" } }) do
        result = manager.remove(["example"])

        expect(result).to be(true)
        expect_package_json_with_content({
          "dependencies" => {
            "example2" => "^0.0.0"
          }
        })
      end
    end

    context "when the package is not there" do
      it "returns false" do
        expect(manager.remove(["example"])).to be(false)
      end
    end

    context "when the package manager errors" do
      it "returns false" do
        manager # ensure the package.json is valid when the manager is created

        File.write("package.json", "{},")

        expect(manager.remove(["example"])).to be(false)
      end
    end

    context "when the current working directory is changed" do
      it "interacts with the right package.json" do
        with_package_json_file({ "dependencies" => { "example" => "^0.0.0", "example2" => "^0.0.0" } }) do
          manager # initialize the package.json in the current directory

          within_subdirectory("subdir") do
            File.write("package.json", "{},")

            expect(manager.remove(["example"])).to be(true)
          end

          expect_package_json_with_content({
            "dependencies" => {
              "example2" => "^0.0.0"
            }
          })
        end
      end
    end
  end

  describe "#remove!" do
    before do
      # yarn requires that a lockfile exist for remove to work
      File.write("yarn.lock", "")
    end

    it "returns nil" do
      with_package_json_file({ "dependencies" => { "example" => "^0.0.0", "example2" => "^0.0.0" } }) do
        result = manager.remove!(["example"])

        expect(result).to be_nil
        expect_manager_to_be_invoked_with("remove example")
        expect_package_json_with_content({
          "dependencies" => {
            "example2" => "^0.0.0"
          }
        })
      end
    end

    context "when the package is not there" do
      it "raises an error" do
        expect { manager.remove!(["example"]) }.to raise_error(PackageJson::Error)
      end
    end

    context "when the package manager errors" do
      it "returns false" do
        manager # ensure the package.json is valid when the manager is created

        File.write("package.json", "{},")

        expect(manager.remove(["example"])).to be(false)
      end
    end
  end

  describe "#run" do
    before do
      File.write("helper.rb", 'File.write("package_json_run_script_helper.txt", ARGV)')
    end

    it "runs the script" do
      with_package_json_file({ "scripts" => { "rspec-test-helper" => "ruby helper.rb" } }) do
        result = manager.run("rspec-test-helper")

        expect(result).to be(true)
        expect_manager_to_be_invoked_with("run rspec-test-helper")
        expect(File.read("package_json_run_script_helper.txt")).to eq("[]")
      end
    end

    it "passes args correctly" do
      with_package_json_file({ "scripts" => { "rspec-test-helper" => "ruby helper.rb" } }) do
        result = manager.run("rspec-test-helper", ["--silent", "--flag", "value"])

        expect(result).to be(true)
        expect_manager_to_be_invoked_with("run rspec-test-helper --silent --flag value")
        expect(File.read("package_json_run_script_helper.txt")).to eq('["--silent", "--flag", "value"]')
      end
    end

    context "when the script is not there" do
      it "returns false" do
        with_package_json_file do
          result = manager.run("rspec-test-helper")

          expect(result).to be(false)
          expect_manager_to_be_invoked_with("run rspec-test-helper")
        end
      end
    end

    context "when the package manager errors" do
      it "returns false" do
        manager # ensure the package.json is valid when the manager is created

        File.write("package.json", "{},")

        expect(manager.remove(["example"])).to be(false)
      end
    end

    it "supports the silent option" do
      with_package_json_file({ "scripts" => { "rspec-test-helper" => "ruby helper.rb" } }) do
        result = manager.run("rspec-test-helper", silent: true)

        expect(result).to be(true)
        expect_manager_to_be_invoked_with("run --silent rspec-test-helper")
        expect(File.read("package_json_run_script_helper.txt")).to eq("[]")
      end
    end

    it "supports the silent option with args" do
      with_package_json_file({ "scripts" => { "rspec-test-helper" => "ruby helper.rb" } }) do
        result = manager.run("rspec-test-helper", ["--silent", "value", "--flag"], silent: true)

        expect(result).to be(true)
        expect_manager_to_be_invoked_with("run --silent rspec-test-helper --silent value --flag")
        expect(File.read("package_json_run_script_helper.txt")).to eq('["--silent", "value", "--flag"]')
      end
    end

    context "when the current working directory is changed" do
      it "interacts with the right package.json" do
        with_package_json_file({ "scripts" => { "rspec-test-helper" => "ruby helper.rb" } }) do
          manager # initialize the package.json in the current directory

          within_subdirectory("subdir") do
            File.write("package.json", "{},")

            expect(manager.run("rspec-test-helper")).to be(true)
          end

          expect_manager_to_be_invoked_with("run rspec-test-helper")
          expect(File.read("package_json_run_script_helper.txt")).to eq("[]")
        end
      end
    end
  end

  describe "#run!" do
    before do
      File.write("helper.rb", 'File.write("package_json_run_script_helper.txt", ARGV)')
    end

    it "returns nil" do
      with_package_json_file({ "scripts" => { "rspec-test-helper" => "ruby helper.rb" } }) do
        result = manager.run!("rspec-test-helper")

        expect(result).to be_nil
        expect_manager_to_be_invoked_with("run rspec-test-helper")
        expect(File.read("package_json_run_script_helper.txt")).to eq("[]")
      end
    end

    context "when the script is not there" do
      it "raises an error" do
        with_package_json_file do
          expect { manager.run!("rspec-test-helper") }.to raise_error(PackageJson::Error)

          expect_manager_to_be_invoked_with("run rspec-test-helper")
        end
      end
    end

    context "when the package manager errors" do
      it "raises an error" do
        manager # ensure the package.json is valid when the manager is created

        File.write("package.json", "{},")

        expect { manager.run!("rspec-test-helper") }.to raise_error(PackageJson::Error)
      end
    end
  end

  describe "#native_run_command" do
    it "returns the full command" do
      expect(manager.native_run_command("my-script")).to eq([package_manager_binary, "run", "my-script"])
    end

    it "includes args" do
      expect(manager.native_run_command("my-script", ["--flag", "value"])).to eq([
        package_manager_binary, "run", "my-script", "--flag", "value"
      ])
    end

    it "includes the silent option" do
      expect(manager.native_run_command("my-script", ["--flag", "value"], silent: true)).to eq([
        package_manager_binary, "run", "--silent", "my-script", "--flag", "value"
      ])
    end
  end

  describe "#native_exec_command" do
    let(:bin_path) do
      p = File.join(Dir.pwd, "node_modules", ".bin")
      # :nocov:
      p = p.tr("/", "\\") if Gem.win_platform?
      # :nocov:
      p
    end

    it "returns the full command" do
      expect(manager.native_exec_command("webpack")).to eq(["#{bin_path}/webpack"])
    end

    it "includes args" do
      expect(manager.native_exec_command("webpack", ["--flag", "value"])).to eq([
        "#{bin_path}/webpack", "--flag", "value"
      ])
    end

    context "when yarn bin errors" do
      before do
        allow(Open3).to receive(:capture3).and_return(["", "oh noes!", Struct::Status.new(1)])
      end

      it "raises an error" do
        expect { manager.native_exec_command("webpack") }.to raise_error(
          PackageJson::Error,
          "#{package_manager_binary} bin failed with exit code 1: oh noes!"
        )
      end
    end

    context "when yarn bin output contains CSI sequences" do
      before do
        # Simulate output from concurrently which includes ANSI escape sequences
        bin_path_with_csi = "\e[2K\e[1G#{bin_path}\n"
        allow(Open3).to receive(:capture3).and_return([bin_path_with_csi, "", Struct::Status.new(0)])
      end

      it "strips CSI sequences from the path" do
        expect(manager.native_exec_command("webpack")).to eq(["#{bin_path}/webpack"])
      end

      it "strips CSI sequences from the path with args" do
        expect(manager.native_exec_command("webpack", ["--flag", "value"])).to eq([
          "#{bin_path}/webpack", "--flag", "value"
        ])
      end
    end
  end
end
