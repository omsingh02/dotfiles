-- =============================================================================
-- VS-INIT.LUA (Optimized strictly for vscode-neovim backend)
-- =============================================================================

-- Safety check: Only load this if running inside VS Code
if not vim.g.vscode then
    return
end

local vscode = require('vscode')

-- =============================================================================
-- LEADER KEY & CORE OPTIONS
-- =============================================================================
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Only keep options that affect the text-editing engine itself
vim.opt.clipboard = "unnamedplus"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.scrolloff = 8

-- =============================================================================
-- TEXT MOTIONS & VIM KEYMAPS
-- =============================================================================

-- The Holy Grail: jk to escape insert mode
vim.keymap.set("i", "jk", "<Esc>", { noremap = true })

-- Clear search highlights
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Keep cursor centered when scrolling
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- Keep search results centered
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Move selected lines up/down in visual mode
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })

-- =============================================================================
-- VS CODE INTEGRATION KEYMAPS
-- (Replacing Telescope, Mason, and Split Navigation)
-- =============================================================================

-- File Navigation (Replaces Telescope)
vim.keymap.set("n", "<leader>ff", function() vscode.call("workbench.action.quickOpen") end)
vim.keymap.set("n", "<leader>fg", function() vscode.call("workbench.action.findInFiles") end)
vim.keymap.set("n", "<leader>fb", function() vscode.call("workbench.action.showAllEditors") end)

-- Window/Pane Navigation (Let VS Code handle the splits instead of Vim)
vim.keymap.set("n", "<C-h>", function() vscode.call("workbench.action.navigateLeft") end)
vim.keymap.set("n", "<C-l>", function() vscode.call("workbench.action.navigateRight") end)
vim.keymap.set("n", "<C-k>", function() vscode.call("workbench.action.navigateUp") end)
vim.keymap.set("n", "<C-j>", function() vscode.call("workbench.action.navigateDown") end)

-- Editor/Buffer Management
vim.keymap.set("n", "<leader>w", function() vscode.call("workbench.action.files.save") end)
vim.keymap.set("n", "<leader>x", function() vscode.call("workbench.action.closeActiveEditor") end)
vim.keymap.set("n", "<leader>n", function() vscode.call("workbench.action.nextEditor") end)
vim.keymap.set("n", "<leader>p", function() vscode.call("workbench.action.previousEditor") end)

-- LSP / Code Intelligence (Replaces Mason/native LSP)
vim.keymap.set("n", "K", function() vscode.call("editor.action.showHover") end)
vim.keymap.set("n", "gd", function() vscode.call("editor.action.revealDefinition") end)
vim.keymap.set("n", "gr", function() vscode.call("editor.action.goToReferences") end)
vim.keymap.set("n", "<leader>rn", function() vscode.call("editor.action.rename") end)
vim.keymap.set("n", "<leader>ca", function() vscode.call("editor.action.quickFix") end)

-- =============================================================================
-- AUTOCOMMANDS
-- =============================================================================

-- Brief highlight on yank (Visual feedback works nicely through the extension)
vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function() vim.highlight.on_yank({ timeout = 40 }) end,
})
-- =============================================================================
-- ONE-SHOT COMPILE & RUN (C / C++)
-- =============================================================================
vim.keymap.set("n", "<leader>r", function()
    local vscode = require('vscode')

    -- 1. Force save the current file so you don't compile old code
    vscode.call('workbench.action.files.save')

    -- 2. Extract file details from Neovim's background buffer
    local filepath = vim.fn.expand('%:p')     -- Full absolute path (e.g., /home/user/main.c)
    local output_bin = vim.fn.expand('%:p:r') -- Full path WITHOUT extension (/home/user/main)
    local ext = vim.fn.expand('%:e')          -- Just the extension (c or cpp)

    -- 3. Route to the correct compiler
    local compiler = ""
    if ext == "c" then
        compiler = "gcc"
    elseif ext == "cpp" or ext == "cxx" then
        compiler = "g++"
    else
        print("Not a C or C++ file!")
        return
    end

    -- 4. Build the shell command
    -- (Clears the terminal, compiles with warnings, and runs the binary if successful)
    local cmd = string.format("clear && %s -Wall -Wextra '%s' -o '%s' && '%s'\r", compiler, filepath, output_bin, output_bin)

    -- 5. Focus the VS Code integrated terminal and inject the keystrokes
    vscode.call('workbench.action.terminal.focus')
    vscode.call('workbench.action.terminal.sendSequence', { args = { text = cmd } })

end, { desc = "Compile and Run C/C++" })

-- =============================================================================
-- TERMINAL TOGGLE QUICK-KEY
-- =============================================================================
-- Optional: A quick way to hide the terminal again when you are done looking at it
vim.keymap.set("n", "<leader>t", function()
    vscode.call("workbench.action.terminal.toggleTerminal")
end, { desc = "Toggle Terminal" })
