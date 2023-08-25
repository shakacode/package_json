# frozen_string_literal: true

require "spec_helper"

RSpec.describe PackageJson::Managers::Base do
  subject(:base) { described_class.new(instance_double(PackageJson), binary_name: "base") }

  describe "#binary" do
    it "returns the expected value" do
      expect(base.binary).to be("base")
    end
  end

  describe "#version" do
    require "open3"

    Struct.new("Status", :exit_code) do
      def success?
        exit_code.zero?
      end

      def exitstatus
        exit_code
      end
    end

    before do
      allow(Open3).to receive(:capture3).and_return(["1.2.3\n", "", Struct::Status.new(0)])
    end

    it "calls the package manager with --version" do
      base.version

      expect(Open3).to have_received(:capture3).with("base --version")
    end

    it "returns the output without a trailing newline" do
      expect(base.version).to eq("1.2.3")
    end

    context "when the package manager errors" do
      before do
        allow(Open3).to receive(:capture3).and_return(["", "oh noes!", Struct::Status.new(1)])
      end

      it "raises an error" do
        expect { base.version }.to raise_error(
          PackageJson::Error,
          "base --version failed with exit code 1: oh noes!"
        )
      end
    end
  end

  describe "#install" do
    it "does not have an implementation" do
      expect { base.install }.to raise_error PackageJson::NotImplementedError
    end
  end

  describe "#install!" do
    it "does not have an implementation" do
      expect { base.install! }.to raise_error PackageJson::NotImplementedError
    end
  end

  describe "#native_install_command" do
    it "does not have an implementation" do
      expect { base.native_install_command }.to raise_error PackageJson::NotImplementedError
    end
  end

  describe "#add" do
    it "does not have an implementation" do
      expect { base.add([]) }.to raise_error PackageJson::NotImplementedError
    end
  end

  describe "#add!" do
    it "does not have an implementation" do
      expect { base.add!([]) }.to raise_error PackageJson::NotImplementedError
    end
  end

  describe "#remove" do
    it "does not have an implementation" do
      expect { base.remove([]) }.to raise_error PackageJson::NotImplementedError
    end
  end

  describe "#remove!" do
    it "does not have an implementation" do
      expect { base.remove!([]) }.to raise_error PackageJson::NotImplementedError
    end
  end

  describe "#run" do
    it "does not have an implementation" do
      expect { base.run("") }.to raise_error PackageJson::NotImplementedError
    end
  end

  describe "#run!" do
    it "does not have an implementation" do
      expect { base.run!("") }.to raise_error PackageJson::NotImplementedError
    end
  end

  describe "#native_run_command" do
    it "does not have an implementation" do
      expect { base.native_run_command("") }.to raise_error PackageJson::NotImplementedError
    end
  end
end
