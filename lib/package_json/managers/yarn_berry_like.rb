class PackageJson
  module Managers
    class YarnBerryLike < Base
      def initialize(package_json)
        super(package_json, binary_name: "yarn")
      end

      # Installs the dependencies specified in the `package.json` file
      def install(
        frozen: false,
        ignore_scripts: false,
        omit_optional_deps: false
      )
        args = with_native_args(
          frozen: frozen,
          _unsupported: [ignore_scripts, omit_optional_deps]
        )

        raw("install", args)
      end

      # Provides the "native" command for installing dependencies with this package manager for embedding into scripts
      def native_install_command(
        frozen: false,
        ignore_scripts: false,
        omit_optional_deps: false
      )
        args = with_native_args(
          frozen: frozen,
          _unsupported: [ignore_scripts, omit_optional_deps]
        )

        build_full_cmd("install", args)
      end

      # Adds the given packages
      def add(
        packages,
        type: :production,
        ignore_scripts: false,
        omit_optional_deps: false
      )
        args = with_native_args(
          package_type_install_flag(type),
          _unsupported: [ignore_scripts, omit_optional_deps]
        )

        raw("add", args + packages)
      end

      # Removes the given packages
      def remove(
        packages,
        ignore_scripts: false,
        omit_optional_deps: false
      )
        args = with_native_args(
          _unsupported: [ignore_scripts, omit_optional_deps]
        )

        raw("remove", args + packages)
      end

      # Runs the script assuming it is defined in the `package.json` file
      def run(
        script_name,
        args = [],
        silent: false
      )
        raw("run", build_run_args(script_name, args, _silent: silent))
      end

      # Provides the "native" command for running the script with args for embedding into shell scripts
      def native_run_command(
        script_name,
        args = [],
        silent: false
      )
        build_full_cmd("run", build_run_args(script_name, args, _silent: silent))
      end

      def native_exec_command(
        script_name,
        args = []
      )
        build_full_cmd("exec", build_run_args(script_name, args, _silent: false))
      end

      private

      def build_run_args(script_name, args, _silent:)
        [script_name, *args]
      end

      def with_native_args(
        *extra_args,
        frozen: nil,
        _unsupported: []
      )
        args = [*extra_args]

        # we make frozen lockfile behaviour consistent with the other package managers as
        # yarn berry automatically enables frozen lockfile if it detects it's running in CI
        unless frozen.nil?
          flag = "--no-immutable"
          flag = "--immutable" if frozen

          args << flag
        end

        args.compact
      end

      def package_type_install_flag(type)
        case type
        when :production
          nil
        when :dev
          "--dev"
        when :optional
          "--optional"
        else
          raise Error, "unsupported package install type \"#{type}\""
        end
      end
    end
  end
end
