vim.api.nvim_create_autocmd("FileType", {
  pattern = "c",
  callback = function()

    -- indentation
    vim.bo.tabstop     = 4
    vim.bo.shiftwidth  = 4
    vim.bo.softtabstop = 4
    vim.bo.expandtab   = false

    -- auto-insert braces on enter after a function definition
    local function is_func_def(line)
      local trimmed = line:match("^%s*(.-)%s*$")
      if not trimmed:match("%)$") then return false end
      if trimmed:match("^if%s*%(")     or
         trimmed:match("^else")        or
         trimmed:match("^while%s*%(")  or
         trimmed:match("^for%s*%(")    or
         trimmed:match("^switch%s*%(") then
        return false
      end
      return trimmed:match("^[%w_%*%s]+%s[%w_]+%s*%(") ~= nil
    end

    vim.keymap.set("i", "<CR>", function()
      local line = vim.api.nvim_get_current_line()
      local row  = vim.api.nvim_win_get_cursor(0)[1]

      if is_func_def(line) then
        local indent = line:match("^(%s*)")
        local inner  = indent .. string.rep(" ", vim.bo.shiftwidth)
        vim.api.nvim_buf_set_lines(0, row - 1, row, false, {
          line,
          indent .. "{",
          inner,
          indent .. "}",
        })
        vim.api.nvim_win_set_cursor(0, { row + 2, #inner })
      else
        local cr = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
        vim.api.nvim_feedkeys(cr, "n", false)
      end
    end, { buffer = true })

  end,
})
