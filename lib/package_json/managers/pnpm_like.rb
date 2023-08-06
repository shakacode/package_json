class PackageJson
  module Managers
    class PnpmLike < Base
      def install(opts = [])
        run(opts, "install", [])
      end

      def add_and_install(packages, type = :production, opts = [])
        run(opts, "add", [package_type_install_flag(type)] + packages)
      end

      private

      def package_type_install_flag(type)
        case type
        when :production
          "--save-prod"
        when :dev
          "--save-dev"
        when :optional
          "--save-optional"
        else
          raise Error, "unsupported package install type \"#{type}\""
        end
      end
    end
  end
end
