-- ==========================================================================
-- Neovim config — minimal, e-ink friendly, Elm-focused
-- ==========================================================================

-- --------------------------------------------------------------------------
-- Core settings
-- --------------------------------------------------------------------------

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true           -- Line numbers
vim.opt.relativenumber = true   -- Relative line numbers
vim.opt.signcolumn = "yes"      -- Always show sign column (prevents layout shift)
vim.opt.cursorline = true       -- Highlight current line
vim.opt.scrolloff = 8           -- Keep 8 lines visible above/below cursor
vim.opt.wrap = false            -- No line wrapping

vim.opt.tabstop = 4             -- Tab width
vim.opt.shiftwidth = 4          -- Indent width
vim.opt.expandtab = true        -- Spaces not tabs
vim.opt.smartindent = true      -- Smart auto-indent

vim.opt.ignorecase = true       -- Case insensitive search
vim.opt.smartcase = true        -- Unless uppercase is typed
vim.opt.hlsearch = true         -- Highlight search matches
vim.opt.incsearch = true        -- Incremental search

vim.opt.splitright = true       -- Vertical splits open right
vim.opt.splitbelow = true       -- Horizontal splits open below

vim.opt.termguicolors = true    -- True color
vim.opt.background = "light"    -- Light theme for e-ink
vim.opt.updatetime = 250        -- Faster updates
vim.opt.timeoutlen = 300        -- Faster key sequence timeout

vim.opt.clipboard = "unnamedplus" -- System clipboard
vim.opt.undofile = true         -- Persistent undo

-- Elm uses 4 spaces
vim.api.nvim_create_autocmd("FileType", {
    pattern = "elm",
    callback = function()
        vim.opt_local.tabstop = 4
        vim.opt_local.shiftwidth = 4
        vim.opt_local.expandtab = true
    end,
})

-- --------------------------------------------------------------------------
-- Keymaps
-- --------------------------------------------------------------------------

-- Clear search highlight
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Better window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")

-- --------------------------------------------------------------------------
-- Plugin manager: lazy.nvim
-- --------------------------------------------------------------------------

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git", "clone", "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({

    -- ======================================================================
    -- Theme: quiet, high-contrast, light
    -- ======================================================================
    {
        "rose-pine/neovim",
        name = "rose-pine",
        priority = 1000,
        config = function()
            require("rose-pine").setup({
                variant = "dawn", -- light variant
                styles = {
                    italic = false, -- no italics (cleaner on e-ink)
                },
            })
            vim.cmd("colorscheme rose-pine-dawn")
        end,
    },

    -- ======================================================================
    -- Fuzzy finder
    -- ======================================================================
    {
        "nvim-telescope/telescope.nvim",
        branch = "0.1.x",
        dependencies = { "nvim-lua/plenary.nvim" },
        keys = {
            { "<leader>f", "<cmd>Telescope find_files<CR>", desc = "Find files" },
            { "<leader>g", "<cmd>Telescope live_grep<CR>", desc = "Grep" },
            { "<leader>b", "<cmd>Telescope buffers<CR>", desc = "Buffers" },
            { "<leader>/", "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Search in file" },
        },
    },

    -- ======================================================================
    -- Elm
    -- ======================================================================
    {
        "elm-tooling/elm-vim",
        ft = "elm",
    },

    -- ======================================================================
    -- LSP
    -- ======================================================================
    {
        "neovim/nvim-lspconfig",
        config = function()
            local lspconfig = require("lspconfig")

            -- Elm language server
            lspconfig.elmls.setup({})

            -- Keymaps when LSP attaches
            vim.api.nvim_create_autocmd("LspAttach", {
                callback = function(event)
                    local map = function(keys, func, desc)
                        vim.keymap.set("n", keys, func, { buffer = event.buf, desc = desc })
                    end
                    map("gd", vim.lsp.buf.definition, "Go to definition")
                    map("gr", vim.lsp.buf.references, "References")
                    map("K", vim.lsp.buf.hover, "Hover docs")
                    map("<leader>rn", vim.lsp.buf.rename, "Rename")
                    map("<leader>ca", vim.lsp.buf.code_action, "Code action")
                    map("<leader>e", vim.diagnostic.open_float, "Show diagnostic")
                    map("[d", vim.diagnostic.goto_prev, "Previous diagnostic")
                    map("]d", vim.diagnostic.goto_next, "Next diagnostic")
                end,
            })
        end,
    },

    -- ======================================================================
    -- Treesitter: better syntax highlighting
    -- ======================================================================
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter.configs").setup({
                ensure_installed = { "elm", "lua", "json", "markdown", "bash" },
                highlight = { enable = true },
            })
        end,
    },

    -- ======================================================================
    -- Quality of life
    -- ======================================================================

    -- Status line: minimal
    {
        "nvim-lualine/lualine.nvim",
        config = function()
            require("lualine").setup({
                options = {
                    theme = "auto",
                    component_separators = "",
                    section_separators = "",
                },
            })
        end,
    },

}, {
    -- lazy.nvim options
    ui = {
        border = "rounded",
    },
})
