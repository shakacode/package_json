require "json"

def allow_kernel_to_receive_system
  allow(Kernel).to receive(:system).and_wrap_original do |original_method, *args|
    # :nocov:
    # make things quieter by redirecting output to /dev/null
    unless ENV.fetch("PACKAGE_JSON_DEBUG", "false").downcase == "true"
      args[1][1] = File::NULL
      args[1][2] = File::NULL
    end
    # :nocov:

    original_method.call(*args)
  end
end

def expect_package_json_with_content(content)
  expect(File.exist?("package.json")).to be(true)

  expect(JSON.parse(File.read("package.json"))).to eq(content)
end

def expect_manager_to_be_invoked_with(args)
  expect(Kernel).to have_received(:system).with(
    match(/^#{package_manager_cmd} #{args}$/),
    hash_including({ chdir: package_json.path })
  )
end
