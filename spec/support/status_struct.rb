require "open3"

Struct.new("Status", :exit_code) do
  def success?
    exit_code.zero?
  end

  def exitstatus
    exit_code
  end
end
