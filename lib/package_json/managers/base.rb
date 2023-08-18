class PackageJson
  module Managers
    class Base # rubocop:disable Metrics/ClassLength
      # @return [String] the binary to invoke for running the package manager
      attr_reader :binary

      def initialize(package_json, binary_name:)
        # @type [PackageJson]
        @package_json = package_json
        # @type [String]
        @binary = binary_name
      end

      def version
        require "open3"

        command = "#{binary} --version"
        stdout, stderr, status = Open3.capture3(command)

        unless status.success?
          raise PackageJson::Error, "#{command} failed with exit code #{status.exitstatus}: #{stderr}"
        end

        stdout.chomp
      end

      # Installs the dependencies specified in the `package.json` file
      def install(
        frozen: false,
        ignore_scripts: false,
        legacy_peer_deps: false,
        omit_optional_deps: false
      )
        raise NotImplementedError
      end

      # Provides the "native" command for installing dependencies with this package manager for embedding into scripts
      def native_install_command(
        frozen: false,
        ignore_scripts: false,
        legacy_peer_deps: false,
        omit_optional_deps: false
      )
        raise NotImplementedError
      end

      # Installs the dependencies specified in the `package.json` file
      def install!(
        frozen: false,
        ignore_scripts: false,
        legacy_peer_deps: false,
        omit_optional_deps: false
      )
        raise_exited_with_non_zero_code_error unless install(
          frozen: frozen,
          ignore_scripts: ignore_scripts,
          legacy_peer_deps: legacy_peer_deps,
          omit_optional_deps: omit_optional_deps
        )
      end

      # Adds the given packages
      def add(
        packages,
        type: :production,
        ignore_scripts: false,
        legacy_peer_deps: false,
        omit_optional_deps: false
      )
        raise NotImplementedError
      end

      # Adds the given packages
      def add!(
        packages,
        type: :production,
        ignore_scripts: false,
        legacy_peer_deps: false,
        omit_optional_deps: false
      )
        raise_exited_with_non_zero_code_error unless add(
          packages,
          type: type,
          ignore_scripts: ignore_scripts,
          legacy_peer_deps: legacy_peer_deps,
          omit_optional_deps: omit_optional_deps
        )
      end

      # Removes the given packages
      def remove(
        packages,
        ignore_scripts: false,
        legacy_peer_deps: false,
        omit_optional_deps: false
      )
        raise NotImplementedError
      end

      # Removes the given packages
      def remove!(
        packages,
        ignore_scripts: false,
        legacy_peer_deps: false,
        omit_optional_deps: false
      )
        raise_exited_with_non_zero_code_error unless remove(
          packages,
          ignore_scripts: ignore_scripts,
          legacy_peer_deps: legacy_peer_deps,
          omit_optional_deps: omit_optional_deps
        )
      end

      # Runs the script assuming it is defined in the `package.json` file
      def run(
        script_name,
        args = [],
        silent: false
      )
        raise NotImplementedError
      end

      # Runs the script assuming it is defined in the `package.json` file
      def run!(
        script_name,
        args = [],
        silent: false
      )
        raise_exited_with_non_zero_code_error unless run(
          script_name,
          args,
          silent: silent
        )
      end

      # Provides the "native" command for running the script with args for embedding into shell scripts
      def native_run_command(
        script_name,
        args = [],
        silent: false
      )
        raise NotImplementedError
      end

      # Provides the "native" command for executing a package with args for embedding into shell scripts
      def native_exec_command(
        script_name,
        args = []
      )
        raise NotImplementedError
      end

      private

      def raise_exited_with_non_zero_code_error
        raise Error, "#{binary} exited with non-zero code"
      end

      def build_full_cmd(sub_cmd, args)
        [binary, sub_cmd, *args]
      end

      def raw(sub_cmd, args)
        Kernel.system(*build_full_cmd(sub_cmd, args), chdir: @package_json.path)
      end
    end
  end
end
