require "json"

PACKAGE_MANAGER_MAP = {
  "bun" => "1",
  "npm" => "9",
  "yarn" => "1",
  "pnpm" => "8"
}.freeze

def allow_open3_to_receive_capture3_for_package_manager
  require "open3"

  allow(Open3).to receive(:capture3).and_wrap_original do |original_method, *args|
    pm_binary = args[0].split[0]

    pm_major = PACKAGE_MANAGER_MAP[pm_binary]

    # :nocov:
    raise "unexpected Open3.capture3 call" unless pm_major

    # :nocov:

    npx_cmd = npx_binary_cmd(pm_binary, pm_major).join(" ")
    args[0] = "#{npx_cmd}#{args[0].delete_prefix(pm_binary)}"

    original_method.call(*args)
  end
end

def allow_kernel_to_receive_system_for_package_manager
  allow(Kernel).to receive(:system).and_wrap_original do |original_method, *args|
    # :nocov:
    # make things quieter by redirecting output to /dev/null
    unless ENV.fetch("PACKAGE_JSON_DEBUG", "false").downcase == "true"
      args.last[1] = File::NULL
      args.last[2] = File::NULL
    end
    # :nocov:

    # allow initializing the yarn berry template
    unless args.join(" ").start_with?("npx -y yarn@1 init -2")
      pm_binary = args[0]
      pm_major = PACKAGE_MANAGER_MAP[pm_binary]

      # :nocov:
      raise "unexpected Kernel.system call" unless pm_major

      # :nocov:

      # use npx to ensure that the package manager is available
      args.shift
      args.unshift(*npx_binary_cmd(pm_binary, pm_major))
    end

    original_method.call(*args)
  end
end

def npx_binary_cmd(binary, major_version)
  ["npx", "-y", "#{binary}@#{major_version}"]
end

def expect_package_json_with_content(content)
  expect(File.exist?("package.json")).to be(true)

  expect(JSON.parse(File.read("package.json"))).to match(content)
end

def expect_manager_to_be_invoked_with(args)
  expect(Kernel).to have_received(:system).with(
    package_manager_binary,
    # this is technically unsafe if an arg value has spaces in it, but we're not expecting that in tests
    *args.split,
    hash_including({ chdir: package_json.directory })
  )
end
