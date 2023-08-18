class PackageJson
  module Managers
    class YarnClassicLike < Base # rubocop:disable Metrics/ClassLength
      def self.symbol
        :yarn_classic
      end

      def self.cmd
        "yarn"
      end

      def initialize(package_json, manager_cmd: YarnClassicLike.cmd)
        super(package_json, manager_cmd: manager_cmd, name_pretty: "Yarn (classic)")
      end

      # Installs the dependencies specified in the `package.json` file
      def install(
        frozen: false,
        ignore_scripts: false,
        legacy_peer_deps: false,
        omit_optional_deps: false
      )
        args = with_native_args(
          frozen: frozen,
          ignore_scripts: ignore_scripts,
          omit_optional_deps: omit_optional_deps,
          _unsupported: [legacy_peer_deps]
        )

        raw("install", args)
      end

      # Provides the "native" command for installing dependencies with this package manager for embedding into scripts
      def native_install_command(
        frozen: false,
        ignore_scripts: false,
        legacy_peer_deps: false,
        omit_optional_deps: false
      )
        args = with_native_args(
          frozen: frozen,
          ignore_scripts: ignore_scripts,
          omit_optional_deps: omit_optional_deps,
          _unsupported: [legacy_peer_deps]
        )

        build_full_cmd("install", args)
      end

      # Adds the given packages
      def add(
        packages,
        type: :production,
        ignore_scripts: false,
        legacy_peer_deps: false,
        omit_optional_deps: false
      )
        args = with_native_args(
          package_type_install_flag(type),
          ignore_scripts: ignore_scripts,
          omit_optional_deps: omit_optional_deps,
          _unsupported: [legacy_peer_deps]
        )

        raw("add", args + packages)
      end

      # Removes the given packages
      def remove(
        packages,
        ignore_scripts: false,
        legacy_peer_deps: false,
        omit_optional_deps: false
      )
        args = with_native_args(
          ignore_scripts: ignore_scripts,
          omit_optional_deps: omit_optional_deps,
          _unsupported: [legacy_peer_deps]
        )

        raw("remove", args + packages)
      end

      # Runs the script assuming it is defined in the `package.json` file
      def run(
        script_name,
        args = [],
        silent: false
      )
        raw("run", build_run_args(script_name, args, silent: silent))
      end

      # Provides the "native" command for running the script with args for embedding into shell scripts
      def native_run_command(
        script_name,
        args = [],
        silent: false
      )
        build_full_cmd("run", build_run_args(script_name, args, silent: silent))
      end

      def native_exec_command(
        script_name,
        args = []
      )
        [File.join(fetch_bin_path, script_name), *args]
      end

      private

      def fetch_bin_path
        require "open3"

        command = build_full_cmd("bin", []).join(" ")
        stdout, stderr, status = Open3.capture3(command)

        unless status.success?
          raise PackageJson::Error, "#{command} failed with exit code #{status.exitstatus}: #{stderr}"
        end

        stdout.chomp
      end

      def build_run_args(script_name, args, silent:)
        args = [script_name, *args]

        args.unshift("--silent") if silent
        args
      end

      def with_native_args(
        *extra_args,
        frozen: nil,
        ignore_scripts: nil,
        omit_optional_deps: nil,
        _unsupported: []
      )
        args = [*extra_args]

        args << "--frozen-lockfile" if frozen
        args << "--ignore-scripts" if ignore_scripts
        args << "--ignore-optional" if omit_optional_deps

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
