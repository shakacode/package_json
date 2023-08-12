class PackageJson
  module Managers
    class Base
      def initialize(package_json, manager_cmd:)
        # @type [PackageJson]
        @package_json = package_json
        # @type [String]
        @manager_cmd = manager_cmd
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

      # Removes the given packages
      def remove(
        packages,
        ignore_scripts: false,
        legacy_peer_deps: false,
        omit_optional_deps: false
      )
        raise NotImplementedError
      end

      # Runs the script assuming it is defined in the `package.json` file
      def run(
        script_name,
        args = [],
        silent: false
      )
        raise NotImplementedError
      end

      # Provides the "native" command for running the script with args for embedding into shell scripts
      def native_run_command(
        script_name,
        args = [],
        silent: false
      )
        raise NotImplementedError
      end

      private

      def build_full_cmd(cmd, args)
        [@manager_cmd, cmd, *args].join(" ")
      end

      def raw(cmd, args)
        result = Kernel.system build_full_cmd(cmd, args)

        raise Error, "#{@manager_cmd} exited with non-zero code" unless result
      end
    end
  end
end
