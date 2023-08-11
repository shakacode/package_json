class PackageJson
  module Managers
    class YarnLike < Base
      def initialize(package_json, manager_cmd: "yarn")
        super(package_json, manager_cmd: manager_cmd)
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
        args = [script_name, *args]

        args.unshift("--silent") if silent

        raw("run", args)
      end

      private

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
