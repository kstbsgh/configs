vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()

    local function trim(s)
      return s:match("^%s*(.-)%s*$")
    end

    local function parse_def(line)
      local params_str, ret = line:match(
        "^%s*def%s+[%w_]+%s*%((.-)%)%s*%->%s*(.-)%s*:"
      )
      if not params_str then
        params_str = line:match("^%s*def%s+[%w_]+%s*%((.-)%)%s*:")
        ret = nil
      end
      if not params_str then return nil end

      local params = {}
      for raw in (params_str .. ","):gmatch("([^,]+),") do
        raw = trim(raw)
        if raw == "" or raw == "self" or raw == "cls" or raw == "*" then
          goto continue
        end
        local prefix = raw:match("^(%*%*?)") or ""
        local rest   = trim(raw:sub(#prefix + 1))
        local name, ptype = rest:match("^([%w_]+)%s*:%s*(.+)$")
        if name then
          ptype = trim(ptype:match("^(.-)%s*=") or ptype)
        else
          name  = rest:match("^([%w_]+)")
          ptype = nil
        end
        if name and name ~= "" then
          table.insert(params, { name = prefix .. name, ptype = ptype })
        end
        ::continue::
      end

      return { params = params, ret = ret and trim(ret) or nil }
    end

    local function place_cursor_and_insert(row, indent)
      vim.api.nvim_win_set_cursor(0, { row + 1, #indent })
      vim.cmd("startinsert!")
      -- move to correct column
      vim.api.nvim_win_set_cursor(0, { row + 1, #indent })
    end

    -- Ctrl+d: plain docstring at current indent, stay in insert mode
    vim.keymap.set("i", "<C-d>", function()
      local row    = vim.api.nvim_win_get_cursor(0)[1]
      local indent = vim.api.nvim_get_current_line():match("^(%s*)") or ""
      local out = {
        indent .. "'''",
        indent .. "",
        indent .. "'''",
      }
      vim.api.nvim_buf_set_lines(0, row - 1, row, false, out)
      place_cursor_and_insert(row, indent)
    end, { buffer = true })

    -- Ctrl+s and then d : NumPy docstring for nearest def above, stay in insert mode
    vim.keymap.set("i", "<C-s>d", function()
      local row      = vim.api.nvim_win_get_cursor(0)[1]
      local buflines = vim.api.nvim_buf_get_lines(0, 0, row, false)

      local def_line
      for i = #buflines, 1, -1 do
        if buflines[i]:match("^%s*def%s+") then
          def_line = buflines[i]
          break
        end
      end

      local indent = vim.api.nvim_get_current_line():match("^(%s*)") or ""

      if not def_line then
        local out = {
          indent .. "'''",
          indent .. "",
          indent .. "'''",
        }
        vim.api.nvim_buf_set_lines(0, row - 1, row, false, out)
        place_cursor_and_insert(row, indent)
        return
      end

      local info = parse_def(def_line)
      local sub  = indent .. "    "

      local out = {}
      table.insert(out, indent .. "'''")
      table.insert(out, indent .. "Summary.")

      if #info.params > 0 then
        table.insert(out, "")
        table.insert(out, indent .. "Parameters")
        table.insert(out, indent .. "----------")
        for _, p in ipairs(info.params) do
          table.insert(out, indent .. p.name .. " : " .. (p.ptype or "type"))
          table.insert(out, sub    .. "Description.")
        end
      end

      local ret = (info.ret and info.ret ~= "None") and info.ret or "type"
      table.insert(out, "")
      table.insert(out, indent .. "Returns")
      table.insert(out, indent .. "-------")
      table.insert(out, indent .. ret)
      table.insert(out, sub    .. "Description.")
      table.insert(out, indent .. "'''")

      vim.api.nvim_buf_set_lines(0, row - 1, row, false, out)
      place_cursor_and_insert(row, indent)

    end, { buffer = true })

  end,
})
