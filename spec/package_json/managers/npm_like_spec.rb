# frozen_string_literal: true

require "spec_helper"

RSpec.describe PackageJson::Managers::NpmLike do
  subject(:manager) { described_class.new(package_json, manager_cmd: package_manager_cmd) }

  let(:package_manager_cmd) { "npx npm@9" }
  let(:package_json) { PackageJson.new }

  around { |example| within_temp_directory { example.run } }

  before do
    allow(Kernel).to receive(:system).and_wrap_original do |original_method, *args|
      # make things quieter by redirecting output to /dev/null
      original_method.call(*args, 1 => File::NULL, 2 => File::NULL)
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
          File.write("package-lock.json", "{}")

          manager.install(frozen: true)

          expect_manager_to_be_invoked_with("ci")
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

          expect_manager_to_be_invoked_with("install --legacy-peer-deps")
        end
      end

      it "supports omit_optional_deps" do
        with_package_json_file do
          manager.install(omit_optional_deps: true)

          expect_manager_to_be_invoked_with("install --omit=optional")
        end
      end

      it "supports all the options together" do
        with_package_json_file do
          # frozen requires that a lockfile exist
          File.write("package-lock.json", "{}")

          manager.install(
            frozen: true,
            ignore_scripts: true,
            legacy_peer_deps: true,
            omit_optional_deps: true
          )

          expect_manager_to_be_invoked_with("ci --ignore-scripts --legacy-peer-deps --omit=optional")
        end
      end
    end
  end

  describe "#add" do
    it "adds dependencies as production by default" do
      with_package_json_file do
        manager.add(["example"])

        expect_manager_to_be_invoked_with("install --save-prod example")
        expect_package_json_with_content({
          "dependencies" => {
            "example" => "^0.0.0"
          }
        })
      end
    end

    it "supports adding production dependencies" do
      with_package_json_file do
        manager.add(["example"], type: :production)

        expect_manager_to_be_invoked_with("install --save-prod example")
        expect_package_json_with_content({
          "dependencies" => {
            "example" => "^0.0.0"
          }
        })
      end
    end

    it "supports adding dev dependencies" do
      with_package_json_file do
        manager.add(["example"], type: :dev)

        expect_manager_to_be_invoked_with("install --save-dev example")
        expect_package_json_with_content({
          "devDependencies" => {
            "example" => "^0.0.0"
          }
        })
      end
    end

    it "supports adding optional dependencies" do
      with_package_json_file do
        manager.add(["example"], type: :optional)

        expect_manager_to_be_invoked_with("install --save-optional example")
        expect_package_json_with_content({
          "optionalDependencies" => {
            "example" => "^0.0.0"
          }
        })
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

          expect_manager_to_be_invoked_with("install --save-prod --ignore-scripts example")
        end
      end

      it "supports legacy_peer_deps" do
        with_package_json_file do
          manager.add(["example"], legacy_peer_deps: true)

          expect_manager_to_be_invoked_with("install --save-prod --legacy-peer-deps example")
        end
      end

      it "supports omit_optional_deps" do
        with_package_json_file do
          manager.add(["example"], omit_optional_deps: true)

          expect_manager_to_be_invoked_with("install --save-prod --omit=optional example")
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

          expect_manager_to_be_invoked_with(
            "install --save-prod --ignore-scripts --legacy-peer-deps --omit=optional example"
          )
        end
      end
    end
  end

  describe "#remove" do
    it "removes the package" do
      with_package_json_file({ "dependencies" => { "example" => "^0.0.0", "example2" => "^0.0.0" } }) do
        manager.remove(["example"])

        expect_manager_to_be_invoked_with("remove example")
        expect_package_json_with_content({
          "dependencies" => {
            "example2" => "^0.0.0"
          }
        })
      end
    end

    context "when passing the usual options" do
      it "supports ignore_scripts" do
        with_package_json_file({ "dependencies" => { "example" => "^0.0.0", "example2" => "^0.0.0" } }) do
          manager.remove(["example"], ignore_scripts: true)

          expect_manager_to_be_invoked_with("remove --ignore-scripts example")
        end
      end

      it "supports legacy_peer_deps" do
        with_package_json_file({ "dependencies" => { "example" => "^0.0.0", "example2" => "^0.0.0" } }) do
          manager.remove(["example"], legacy_peer_deps: true)

          expect_manager_to_be_invoked_with("remove --legacy-peer-deps example")
        end
      end

      it "supports omit_optional_deps" do
        with_package_json_file({ "dependencies" => { "example" => "^0.0.0", "example2" => "^0.0.0" } }) do
          manager.remove(["example"], omit_optional_deps: true)

          expect_manager_to_be_invoked_with("remove --omit=optional example")
        end
      end

      it "supports all the options together" do
        with_package_json_file({ "dependencies" => { "example" => "^0.0.0", "example2" => "^0.0.0" } }) do
          manager.remove(
            ["example"],
            ignore_scripts: true,
            legacy_peer_deps: true,
            omit_optional_deps: true
          )

          expect_manager_to_be_invoked_with("remove --ignore-scripts --legacy-peer-deps --omit=optional example")
        end
      end
    end
  end

  describe "#run" do
    before do
      File.write("helper.rb", 'File.write("package_json_run_script_helper.txt", ARGV)')
    end

    it "runs the script" do
      with_package_json_file({ "scripts" => { "rspec-test-helper" => "ruby helper.rb" } }) do
        manager.run("rspec-test-helper")

        expect_manager_to_be_invoked_with("run rspec-test-helper --")
        expect(File.read("package_json_run_script_helper.txt")).to eq("[]")
      end
    end

    it "passes args correctly" do
      with_package_json_file({ "scripts" => { "rspec-test-helper" => "ruby helper.rb" } }) do
        manager.run("rspec-test-helper", ["--silent", "--flag", "value"])

        expect_manager_to_be_invoked_with("run rspec-test-helper -- --silent --flag value")
        expect(File.read("package_json_run_script_helper.txt")).to eq('["--silent", "--flag", "value"]')
      end
    end

    context "when the script is not there" do
      it "raises an error" do
        with_package_json_file do
          expect { manager.run("rspec-test-helper") }.to raise_error(PackageJson::Error)

          expect_manager_to_be_invoked_with("run rspec-test-helper --")
        end
      end
    end

    it "supports the silent option" do
      with_package_json_file({ "scripts" => { "rspec-test-helper" => "ruby helper.rb" } }) do
        manager.run("rspec-test-helper", silent: true)

        expect_manager_to_be_invoked_with("run --silent rspec-test-helper --")
        expect(File.read("package_json_run_script_helper.txt")).to eq("[]")
      end
    end

    it "supports the silent option with args" do
      with_package_json_file({ "scripts" => { "rspec-test-helper" => "ruby helper.rb" } }) do
        manager.run("rspec-test-helper", ["--silent", "value", "--flag"], silent: true)

        expect_manager_to_be_invoked_with("run --silent rspec-test-helper -- --silent value --flag")
        expect(File.read("package_json_run_script_helper.txt")).to eq('["--silent", "value", "--flag"]')
      end
    end
  end
end
