-- =============================================================================
-- LEADER KEY
-- =============================================================================
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- =============================================================================
-- OPTIONS
-- =============================================================================
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.mouse = "a"
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.undofile = true
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.wrap = false
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.title = true
vim.opt.hlsearch = false
vim.opt.showmode = false
vim.opt.wildmode = { "longest", "list", "full" }

-- System clipboard (schedule to avoid startup overhead)
vim.schedule(function() vim.opt.clipboard = "unnamedplus" end)

-- =============================================================================
-- LAZY.NVIM BOOTSTRAP
-- =============================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- =============================================================================
-- PLUGINS
-- =============================================================================
require("lazy").setup({
  -- Theme: theme colors loaded from ~/.cache/theme/colors-nvim.lua
  -- No plugin needed — colorscheme lives in ~/.config/nvim/colors/theme.lua
  { "catppuccin/nvim", name = "catppuccin", priority = 1000, opts = {
    flavour = "mocha",
    no_italic = true,
  }},

  -- Treesitter: better syntax highlighting
  { "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      -- nvim-treesitter API: use the module directly (treesitter.configs was removed)
      local ok, ts = pcall(require, "nvim-treesitter.configs")
      if not ok then
        ts = require("nvim-treesitter")
      end
      ts.setup({
        ensure_installed = { "c", "cpp", "java", "python", "lua", "bash", "json", "yaml", "markdown", "sql" },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  -- LSP Configuration & Mason
  { "neovim/nvim-lspconfig" },
  { "williamboman/mason.nvim", opts = {} },
  { "williamboman/mason-lspconfig.nvim", opts = {
    ensure_installed = { "clangd", "pylsp", "jdtls", "lua_ls", "sqls" },
    automatic_installation = true,
  }},

  -- Completion
  { "hrsh7th/nvim-cmp", dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip",
    "rafamadriz/friendly-snippets",
  }, config = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")
    cmp.setup({
      snippet = {
        expand = function(args) luasnip.lsp_expand(args.body) end,
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-e>"] = cmp.mapping.abort(),
        ["<CR>"] = cmp.mapping.confirm({ select = true }),
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then cmp.select_next_item()
          elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
          else fallback() end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then luasnip.jump(-1)
          else fallback() end
        end, { "i", "s" }),
      }),
      sources = cmp.config.sources({
        { name = "nvim_lsp", priority = 1000 },
        { name = "luasnip", priority = 750 },
        { name = "buffer", priority = 500, keyword_length = 2 },
        { name = "path", priority = 250 },
      }),
    })
  end },

  -- Telescope: fuzzy finder
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },

  -- Autopairs
  { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },

  -- Git signs in gutter
  { "lewis6991/gitsigns.nvim", opts = {} },

  -- Status line
  { "nvim-lualine/lualine.nvim", opts = { options = { theme = "auto" } } },


  -- Comment toggling (line: gcc/gc, block: gbc/gb)
  {
    "numToStr/Comment.nvim",
    config = function()
      local ft = require("Comment.ft")
      local U = require("Comment.utils")

      -- Neovim 0.11+ compatibility: get_parser returns nil without erroring
      local orig_calculate = ft.calculate
      ft.calculate = function(ctx)
        local ok, parser = pcall(vim.treesitter.get_parser, 0)
        if not ok or not parser then
          return ft.get(vim.bo.filetype, ctx.ctype)
        end
        return orig_calculate(ctx)
      end

      -- Handle empty commentstring gracefully
      local orig_unwrap = U.unwrap_cstr
      U.unwrap_cstr = function(cstr)
        if not cstr or cstr == "" then
          error({ msg = "Option 'commentstring' is empty." })
        end
        return orig_unwrap(cstr)
      end

      -- Safe error catcher that handles raw Lua error strings
      U.catch = function(fn, ...)
        xpcall(fn, function(err)
          local msg = type(err) == "table" and err.msg or tostring(err):gsub(".*:%d+: ", "")
          vim.notify(string.format("[Comment.nvim] %s", msg), vim.log.levels.WARN)
        end, ...)
      end

      require("Comment").setup()
    end,
  },

  -- Surround (cs, ds, ys)
  { "kylechui/nvim-surround", event = "VeryLazy", opts = {} },

  -- Inline color preview
  { "norcalli/nvim-colorizer.lua", opts = {} },

}, { performance = { rtp = { disabled_plugins = {
  "gzip", "tarPlugin", "zipPlugin", "tohtml", "tutor", "netrwPlugin"
}}}})

-- =============================================================================
-- COLORSCHEME
-- =============================================================================
vim.cmd.colorscheme("theme")

-- =============================================================================
-- LSP SETUP (Neovim 0.11 Native vim.lsp.config API)
-- =============================================================================
-- Ensure Mason bin is always on PATH for LSP executables
local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
if not vim.env.PATH:find(mason_bin, 1, true) then
  vim.env.PATH = mason_bin .. ":" .. vim.env.PATH
end

local cmp_caps = require("cmp_nvim_lsp").default_capabilities()

-- Apply completion capabilities to all LSPs
vim.lsp.config("*", {
  capabilities = cmp_caps,
})

-- C / C++ (clangd)
vim.lsp.config("clangd", {
  cmd = {
    "clangd",
    "--background-index",
    "--clang-tidy",
    "--header-insertion=iwyu",
    "--completion-style=detailed",
    "--function-arg-placeholders=true",
    "--fallback-style=llvm",
  },
})

-- Java (JDTLS with single-file fallback support)
vim.lsp.config("jdtls", {
  workspace_required = false,
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    local root = vim.fs.root(bufnr, { "mvnw", "gradlew", "pom.xml", "build.gradle", ".git" })
      or (fname ~= "" and vim.fs.dirname(fname))
      or vim.fn.getcwd()
    on_dir(root)
  end,
})

-- SQL (sqls with MariaDB connection)
vim.lsp.config("sqls", {
  settings = { sqls = {
    connections = {{
      driver = "mysql",
      dataSourceName = "faulter@unix(/run/mysqld/mysqld.sock)/",
    }},
  }},
})

-- Enable all configured language servers
vim.lsp.enable({ "clangd", "jdtls", "pylsp", "lua_ls", "sqls" })

-- =============================================================================
-- LSP KEYMAPS (applied when an LSP attaches to a buffer)
-- =============================================================================
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc })
    end
    map("n", "gd", vim.lsp.buf.definition, "Go to definition")
    map("n", "gr", vim.lsp.buf.references, "Show references")
    map("n", "K", vim.lsp.buf.hover, "Hover docs")
    map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
    map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("n", "<leader>e", vim.diagnostic.open_float, "Show diagnostic")
    map("n", "[d", vim.diagnostic.goto_prev, "Prev diagnostic")
    map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
    map("i", "<C-h>", vim.lsp.buf.signature_help, "Signature help")
  end,
})

-- =============================================================================
-- KEYMAPS
-- =============================================================================
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })

-- Delete with `c` into black hole (preserve yank register)
vim.keymap.set("n", "c", '"_c')
vim.keymap.set("n", "C", '"_C')

-- Toggle spell check
vim.keymap.set("n", "<leader>o", "<cmd>setlocal spell! spelllang=en_us<CR>", { desc = "Toggle spellcheck" })

-- Save as sudo
vim.api.nvim_create_user_command("W", "execute 'silent! write !sudo tee % >/dev/null' | edit!", { desc = "Sudo write" })

-- Window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")

-- Buffer navigation
vim.keymap.set("n", "<leader>n", ":bn<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>p", ":bp<CR>", { desc = "Previous buffer" })
vim.keymap.set("n", "<leader>x", ":bd<CR>", { desc = "Close buffer" })

-- Save
vim.keymap.set("n", "<leader>w", ":w<CR>", { desc = "Save file" })

-- Move selected lines up/down in visual mode
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })

-- Keep cursor centered when scrolling
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- Keep search results centered
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- =============================================================================
-- AUTOCMDS
-- =============================================================================

-- Brief highlight on yank (visual feedback)
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function() vim.highlight.on_yank({ timeout = 40 }) end,
})

-- Strip trailing whitespace on save (cursor preserved)
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    if not vim.bo.modifiable then return end
    local pos = vim.api.nvim_win_get_cursor(0)
    vim.cmd([[%s/\s\+$//e]])
    pcall(vim.api.nvim_win_set_cursor, 0, pos)
  end,
})

-- Disable auto-comment on newline
vim.api.nvim_create_autocmd("FileType", {
  callback = function() vim.opt_local.formatoptions:remove({ "c", "r", "o" }) end,
})


-- =============================================================================
-- CUSTOM MODULES: SNIPPETS, RUNNERS & GIT INTEGRATION
-- =============================================================================
require("config.snippets")
local runner = require("config.runner")

-- Code Execution & DSA Runner
vim.keymap.set("n", "<leader>r", runner.run_code, { desc = "Run code in split terminal" })
vim.keymap.set("n", "<leader>rc", runner.run_code, { desc = "Run code in split terminal" })
vim.keymap.set("n", "<leader>ri", runner.run_with_input, { desc = "Run with input.txt" })
vim.keymap.set("n", "<leader>mq", function() runner.run_sql_query(false) end, { desc = "Execute SQL query" })
vim.keymap.set("v", "<leader>mq", function() runner.run_sql_query(true) end, { desc = "Execute selected SQL" })

-- Format code via LSP
vim.keymap.set({ "n", "v" }, "<leader>cf", function()
  vim.lsp.buf.format({ async = true })
end, { desc = "Format buffer / selection" })

-- Git Integration (Telescope + Gitsigns)
vim.keymap.set("n", "<leader>gs", builtin.git_status, { desc = "Git status" })
vim.keymap.set("n", "<leader>gc", builtin.git_commits, { desc = "Git commits" })
vim.keymap.set("n", "<leader>gb", builtin.git_branches, { desc = "Git branches" })

local has_gs, gs = pcall(require, "gitsigns")
if has_gs then
  vim.keymap.set("n", "]c", function()
    if vim.wo.diff then return "]c" end
    vim.schedule(function() gs.next_hunk() end)
    return "<Ignore>"
  end, { expr = true, desc = "Next git hunk" })

  vim.keymap.set("n", "[c", function()
    if vim.wo.diff then return "[c" end
    vim.schedule(function() gs.prev_hunk() end)
    return "<Ignore>"
  end, { expr = true, desc = "Previous git hunk" })

  vim.keymap.set("n", "<leader>hs", gs.stage_hunk, { desc = "Stage hunk" })
  vim.keymap.set("n", "<leader>hr", gs.reset_hunk, { desc = "Reset hunk" })
  vim.keymap.set("v", "<leader>hs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, { desc = "Stage selected hunk" })
  vim.keymap.set("v", "<leader>hr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, { desc = "Reset selected hunk" })
  vim.keymap.set("n", "<leader>hp", gs.preview_hunk, { desc = "Preview hunk inline" })
  vim.keymap.set("n", "<leader>hb", function() gs.blame_line({ full = true }) end, { desc = "Blame line" })
  vim.keymap.set("n", "<leader>hd", gs.diffthis, { desc = "Diff this buffer" })
end

-- Terminal Mode Escaping
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
