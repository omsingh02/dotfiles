-- Treesitter parsers wanted. They are installed by hand, not at start-up (runbook 20; needs the tree-sitter CLI):
--   nvim --headless -c 'lua require("nvim-treesitter").install(require("config.parsers")):wait(600000)' -c qa
return { "c", "cpp", "java", "python", "lua", "bash", "json", "yaml", "markdown", "sql" }
