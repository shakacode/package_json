class PackageJson
  module Managers
    class Base
      # @param [String] manager_cmd
      # @param [PackageJson | nil] [package_json]
      def initialize(manager_cmd, package_json = nil)
        # @type [String]
        @manager_cmd = manager_cmd
        # @type [PackageJson]
        @package_json = package_json
      end

      # Installs the dependencies specified in the `package.json` file
      #
      # @todo support "frozen"
      def install(opts = [])
        raise NotImplementedError
      end

      # @param [Array<String>] packages
      # @param [Symbol] type
      # @param [Array<String>] [opts]
      def add_and_install(packages, type = :production, opts = [])
        raise NotImplementedError
      end

      private

      def run(opts, cmd, args)
        result = Kernel.system [@manager_cmd, *opts, cmd, *args].join(" ")

        raise Error, "#{@manager_cmd} exited with non-zero code" unless result
      end
    end
  end
end
