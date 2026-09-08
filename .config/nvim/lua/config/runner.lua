local M = {}

-- Open terminal split and execute command
local function exec_in_term(cmd)
  vim.cmd("silent! write")
  vim.cmd("botright 12split")
  vim.cmd("terminal " .. cmd)
  vim.cmd("startinsert")
end

-- Run current file interactively based on filetype
function M.run_code()
  local ft = vim.bo.filetype
  local file = vim.fn.expand("%:p")

  if file == "" then
    vim.notify("No file to run", vim.log.levels.WARN)
    return
  end

  local cmd = nil
  if ft == "c" then
    cmd = string.format("gcc -O2 -Wall '%s' -o /tmp/c_bin && /tmp/c_bin", file)
  elseif ft == "cpp" then
    cmd = string.format("g++ -O2 -std=c++20 -Wall '%s' -o /tmp/cpp_bin && /tmp/cpp_bin", file)
  elseif ft == "java" then
    cmd = string.format("java '%s'", file)
  elseif ft == "python" then
    cmd = string.format("python3 '%s'", file)
  elseif ft == "sql" then
    cmd = string.format("mariadb -t < '%s'", file)
  elseif ft == "sh" or ft == "bash" then
    cmd = string.format("bash '%s'", file)
  else
    vim.notify("No runner configured for filetype: " .. ft, vim.log.levels.WARN)
    return
  end

  exec_in_term(cmd)
end

-- Run current file with input.txt redirected (DSA / CP workflow)
function M.run_with_input()
  local ft = vim.bo.filetype
  local file = vim.fn.expand("%:p")
  local dir = vim.fn.expand("%:p:h")
  local input_file = dir .. "/input.txt"

  if vim.fn.filereadable(input_file) == 0 then
    input_file = vim.fn.getcwd() .. "/input.txt"
  end

  if vim.fn.filereadable(input_file) == 0 then
    vim.notify("No input.txt found in buffer or project directory", vim.log.levels.WARN)
    return
  end

  local cmd = nil
  if ft == "c" then
    cmd = string.format("gcc -O2 -Wall '%s' -o /tmp/c_bin && /tmp/c_bin < '%s'", file, input_file)
  elseif ft == "cpp" then
    cmd = string.format("g++ -O2 -std=c++20 -Wall '%s' -o /tmp/cpp_bin && /tmp/cpp_bin < '%s'", file, input_file)
  elseif ft == "java" then
    cmd = string.format("java '%s' < '%s'", file, input_file)
  elseif ft == "python" then
    cmd = string.format("python3 '%s' < '%s'", file, input_file)
  else
    vim.notify("Input redirection not configured for: " .. ft, vim.log.levels.WARN)
    return
  end

  exec_in_term(cmd)
end

-- Execute SQL query (current buffer or visual selection) against MariaDB
function M.run_sql_query(is_visual)
  local query = ""
  if is_visual then
    local _, srow, scol = unpack(vim.fn.getpos("'<"))
    local _, erow, ecol = unpack(vim.fn.getpos("'>"))
    local lines = vim.api.nvim_buf_get_lines(0, srow - 1, erow, false)
    if #lines == 0 then return end
    query = table.concat(lines, "\n")
  else
    local line = vim.api.nvim_get_current_line()
    if vim.trim(line) ~= "" then
      query = line
    else
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      query = table.concat(lines, "\n")
    end
  end

  local tmp = "/tmp/nvim_query.sql"
  local f = io.open(tmp, "w")
  if not f then
    vim.notify("Failed to write temporary SQL query file", vim.log.levels.ERROR)
    return
  end
  f:write(query)
  f:close()

  exec_in_term("mariadb -t < " .. tmp)
end

return M
