return {
  is_al2 = function()
    local lines = vim.fn.readfile("/etc/os-release")

    for _, line in ipairs(lines) do
      if line:find("amazon_linux:2", 1, true) then
        return true
      end
    end

    return false
  end,
}
