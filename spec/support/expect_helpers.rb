require "json"

def expect_package_json_with_content(content)
  expect(File.exist?("package.json")).to be(true)

  expect(JSON.parse(File.read("package.json"))).to eq(content)
end

def expect_manager_to_be_invoked_with(args)
  expect(Kernel).to have_received(:system).with(match(/^#{package_manager_cmd} #{args}$/))
end
