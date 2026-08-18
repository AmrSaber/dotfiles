return {
  is_al2 = function()
    local os_file = "/etc/os-release"

    if vim.fn.filereadable(os_file) == 0 then
      return false
    end

    local lines = vim.fn.readfile(os_file)
    for _, line in ipairs(lines) do
      -- trailing colon so this matches AL2 (`amazon_linux:2:`) but not AL2023 (`amazon_linux:2023:`)
      if line:find("amazon_linux:2:", 1, true) then
        return true
      end
    end

    return false
  end,
}
