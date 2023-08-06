class PackageJson
  module Managers
    class YarnLike < Base
      def install(opts = [])
        run(opts, "install", [])
      end

      def add_and_install(packages, type = :production, opts = [])
        run(opts, "add", [package_type_install_flag(type)].compact + packages)
      end

      def remove(packages, opts = [])
        run(opts, "remove", packages)
      end

      private

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
