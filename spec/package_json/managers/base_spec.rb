# frozen_string_literal: true

require "spec_helper"

RSpec.describe PackageJson::Managers::Base do
  subject(:base) { described_class.new(instance_double(PackageJson), manager_cmd: "") }

  describe "#install" do
    it "does not have an implementation" do
      expect { base.install }.to raise_error PackageJson::NotImplementedError
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

  describe "#remove" do
    it "does not have an implementation" do
      expect { base.remove([]) }.to raise_error PackageJson::NotImplementedError
    end
  end

  describe "#run" do
    it "does not have an implementation" do
      expect { base.run("") }.to raise_error PackageJson::NotImplementedError
    end
  end

  describe "#native_run_command" do
    it "does not have an implementation" do
      expect { base.native_run_command("") }.to raise_error PackageJson::NotImplementedError
    end
  end
end
