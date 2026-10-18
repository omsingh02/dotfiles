local M = {}

-- The command is `sh -c SCRIPT sh ARG...`: file names reach the shell only as $1, $2, $3, never as text inside the script, so a
-- name like  x'; rm -rf ~; '.c  is just a name (and Ex never sees it, so % and # in it are not expanded either).
local function sh(script, file, bin, input)
  local argv = { "sh", "-c", script, "sh", file, bin or "" }
  if input then argv[#argv + 1] = input end
  return argv
end

-- A scratch path for the compiled program in the session's runtime directory (mode 700), not in /tmp.
local function scratch(name)
  local dir = vim.fn.stdpath("run")
  vim.fn.mkdir(dir, "p", 448)
  return string.format("%s/%s-%d", dir, name, vim.fn.getpid())
end

-- Open terminal split and execute argv
local function exec_in_term(argv)
  vim.cmd("silent! write")
  vim.cmd("botright 12new")
  vim.fn.jobstart(argv, { term = true })
  vim.cmd("startinsert")
end

-- The command that runs `file` (a {filetype} program), optionally with `input` as its standard input; nil and a reason if
-- there is none. $1 = the file, $2 = the compiled program's path, $3 = the input file.
function M.command(ft, file, input)
  local feed = input and ' < "$3"' or ""
  local cleanup = '; rc=$?; rm -f "$2"; exit "$rc"'
  if ft == "c" then
    return sh('gcc -O2 -Wall "$1" -o "$2" && "$2"' .. feed .. cleanup, file, scratch("c"), input)
  elseif ft == "cpp" then
    return sh('g++ -O2 -std=c++20 -Wall "$1" -o "$2" && "$2"' .. feed .. cleanup, file, scratch("cpp"), input)
  elseif ft == "java" then
    return sh('java "$1"' .. feed, file, nil, input)
  elseif ft == "python" then
    return sh('python3 "$1"' .. feed, file, nil, input)
  elseif input then
    return nil, "Input redirection not configured for: " .. ft
  elseif ft == "sql" then
    return sh('mariadb -t < "$1"', file)
  elseif ft == "sh" or ft == "bash" then
    return sh('bash "$1"', file)
  end
  return nil, "No runner configured for filetype: " .. ft
end

-- Run current file interactively based on filetype
function M.run_code()
  local file = vim.fn.expand("%:p")

  if file == "" then
    vim.notify("No file to run", vim.log.levels.WARN)
    return
  end

  local argv, err = M.command(vim.bo.filetype, file)
  if not argv then
    vim.notify(err, vim.log.levels.WARN)
    return
  end

  exec_in_term(argv)
end

-- Run current file with input.txt redirected (DSA / CP workflow)
function M.run_with_input()
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

  local argv, err = M.command(vim.bo.filetype, file, input_file)
  if not argv then
    vim.notify(err, vim.log.levels.WARN)
    return
  end

  exec_in_term(argv)
end

-- The lines of the Visual selection. The mapping runs while Visual mode is still on, when the '< and '> marks still describe the
-- selection before this one, so the live ends of the selection are read instead.
local function selected_lines()
  local mode = vim.fn.mode()
  local a, b
  if mode == "v" or mode == "V" or mode == "\22" then
    a, b = vim.fn.line("v"), vim.fn.line(".")
  else
    a, b = vim.fn.line("'<"), vim.fn.line("'>")
  end
  return vim.api.nvim_buf_get_lines(0, math.min(a, b) - 1, math.max(a, b), false)
end

-- Execute SQL query (current buffer or visual selection) against MariaDB
function M.run_sql_query(is_visual)
  local query = ""
  if is_visual then
    local lines = selected_lines()
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

  local tmp = scratch("query") .. ".sql"
  local f = io.open(tmp, "w")
  if not f then
    vim.notify("Failed to write temporary SQL query file", vim.log.levels.ERROR)
    return
  end
  f:write(query)
  f:close()

  exec_in_term(sh('mariadb -t < "$1"; rc=$?; rm -f "$1"; exit "$rc"', tmp))
end

return M
