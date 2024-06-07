-- setup taken from tj devries's kickstart: https://github.com/nvim-lua/kickstart.nvim/blob/master/init.lua

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true

vim.opt.ignorecase = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.undofile = true

vim.opt.background = "dark"

--the vim project view (netrw) - not sure if pv makes the most sense
vim.keymap.set("n", "<leader>pv", ":Ex<CR>")

--not sure about these, although the characters only seem to display while typing
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = ".", nbsp = "␣" }

vim.opt.inccommand = "split"

vim.opt.scrolloff = 8

vim.opt.hlsearch = true
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

--not sure I like the diagnostic keymaps because it's a bit awkward on this keyboard
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous [D]iagnostic message" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next [D]iagnostic message" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic [E]rror messags" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

vim.g.py_file_to_run = ""

vim.keymap.set("n", "<leader>b", function ()
    if vim.g.py_file_to_run == "" then
        vim.g.py_file_to_run = vim.split(vim.fn.input "Command to run (e.g., python main.py):", " ")
    end

    local new_buff = vim.api.nvim_create_buf(0, 1)
    vim.api.nvim_command(string.format("botright sb %s", new_buff))
    vim.api.nvim_command("resize 6")
    vim.fn.jobstart(vim.g.py_file_to_run, {
        stdout_buffered = true,
        on_stdout = function (_, data)
            if data then
                vim.api.nvim_buf_set_lines(new_buff, -1, -1, false, data)
            end
        end,
        on_stderr = function (_, data)
            if data then
                vim.api.nvim_buf_set_lines(new_buff, -1, -1, false, data)
            end
        end,
    })
end, {})

vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Highlight when yanking text", 
    group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
    callback = function()
        vim.highlight.on_yank()
    end,
})

local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    vim.fn.system { "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath }
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup {
    { "polirritmico/monokai-nightasty.nvim", 
        opts = { dark_style_background = "transparent",
            color_headers = false,
            lualine_bold = true,
            lazy = false,
            priority = 1000,

            on_highlights = function(highlights, colors)
                highlights.TelescopeNormal = { fg = colors.magenta, bg = colors.charcoal }
            end
        }
    },

    {
	    "nvim-telescope/telescope.nvim", 
        event = "VimEnter",
        branch = "0.1.x",
        dependencies = 
        {
            "nvim-lua/plenary.nvim",
            {
                "nvim-telescope/telescope-fzf-native.nvim",
                build = "make",
                cond = function()
                    return vim.fn.executable "make" == 1
                end
            },
            { "nvim-telescope/telescope-ui-select.nvim" },
        },
        config = function()
            require("telescope").setup
            {
                extensions =
                {
                    ["ui-select"] = { require("telescope.themes").get_dropdown()}
                },
            }
            pcall(require("telescope").load_extension, "fzf")
            pcall(require("telescope").load_extension, "ui-select")

            local builtin = require "telescope.builtin"
            vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
            vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
            vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "[S]earch [F]iles" })
            vim.keymap.set("n", "<leader>ss", builtin.builtin, { desc = "[S]earch [S]elect Telescope" })
            vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
            vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "[S]earch by [G]rep" })
            vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
            vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "[S]earch [R]esume" })
            vim.keymap.set("n", "<leader>s.", builtin.oldfiles, { desc = "[S]earch Recent Files ('.' for repeat)" })
            vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "[ ] Find existing buffers" })
            vim.keymap.set("n", "<leader>st", builtin.treesitter, { desc = "[S]earch [T]reesitter" })

            --vim.keymap.set("n", "<leader>/", builtin.current_buffer_fuzzy_find, { desc = "[/] fuzzy search" })

            --the function here makes the window much smaller and removes the preview pane from the right
            vim.keymap.set("n", "<leader>/", function()
                builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown {
                    winblend = 10,
                    previewer = false,
                })
            end, { desc = "[/] Fuzzily search in current buffer" })

            --search is limited to open files
            vim.keymap.set("n", "<leader>s/", function()
                builtin.live_grep {
                    grep_open_files = true,
                    prompt_title = "Live Grep in Open Files"
                }
            end, { desc = "[S]earch [/] in Open Files" })

            --search config
            vim.keymap.set("n", "<leader>sn", function()
                builtin.find_files { cwd = vim.fn.stdpath "config" }
            end, { desc = "[S]earch [N]eovim files" })

        end,
    },

    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "WhoIsSethDaniel/mason-tool-installer.nvim",

            { "j-hui/fidget.nvim", opts = {} },
            { "folke/neodev.nvim", opts = {} },
        },
        
        config = function()

            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
                callback = function(event)

                    local map = function(keys, func, desc)
                        vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
                    end

                    -- jump to where variable was first declared or where function was defined, etc.
                    -- <C-t> to jump back
                    map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")

                    -- find references for word under cursor
                    map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")

                    -- jump to implementation of word under cursor (not really a python thing)
                    map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")

                    -- jump to type of word under cursor
                    map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")

                    -- fuzzy find symbols in document (variables, functions, types, etc.)
                    map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")

                    -- same as document symbols, but for whole project/workspace
                    map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")
                    --map("<leader>ws", require("telescope.builtin").lsp_workspace_symbols, "[W]orkspace [S]ymbols")

                    --
                    map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")

                    -- code action - not sure what this one does - I assume it's something like when the lsp offers to refactor your code?
                    map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

                    -- opens popup with documentation for word under cursor
                    map("K", vim.lsp.buf.hover, "Hover Documentation")

                    -- goto declaration (header file in C or C++, for instance) - not sure how it's different from definition in python
                    map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

                    -- highlights references for word under cursor if you rest there and clears when you move
                    local client = vim.lsp.get_client_by_id(event.data.client_id)
                    if client and client.server_capabilities.documentHighlightProvider then
                        vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                            buffer = event.buf,
                            callback = vim.lsp.buf.document_highlight,
                        })

                        vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
                            buffer = event.buf, 
                            callback = vim.lsp.buf.clear_references,
                        })
                    end
                end
            })

            -- adds additional capabilities beyond what neovim has
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

            -- add language servers here
            -- github page with available languages: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
            local servers = {
                --pyright = { }, -- shows errors (not as many as pylyzer), but doesn't show class arguments
                jedi_language_server = { settings = { diagnostics = { enable = true } }}, -- shows arguments when creating instances, but doesn't show errors
                --pylyzer = {}, -- doesn't show arguments when creating an instance of a class
                --pylsp = {},
                --basedpyright = { opts = {} }, -- doesn't seem to address my problems with pyright
                html = { },

                lua_ls = {
                    settings = {
                        lua = {
                            completion = {
                                callSnippet = "Replace",
                            },
                        },
                    },
                },
            }

            require("mason").setup()

            local ensure_installed = vim.tbl_keys(servers or {})

            require("mason-tool-installer").setup { ensure_installed = ensure_installed }
            require("mason-lspconfig").setup {
                handlers = {
                    function(server_name)
                        local server = servers[server_name] or {}
                        server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
                        require("lspconfig")[server_name].setup(server)
                    end,
                },
            }

        end, -- end of config function
    }, -- end of lsp config

    -- in the kickstart project, this is where stevarc/conform.nvim is added, which allows autoformatting
    -- you can plug in language formatters, such as black for python, or prettier for javascript

    { -- autocompletion
        -- note: there doesn't seem to be a python autocompletion engine on the github page, but there don't seem to be any language-specific plugins
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",
        dependencies = {
            {
                "L3MON4D3/LuaSnip",
                build = (function()
                    if vim.fn.has "win32" == 1 or vim.fn.executable "make" == 0 then
                        return
                    end
                    return "make install_jsregexp"
                end)(),
            },
            "saadparwaiz1/cmp_luasnip",
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-path",
        },
        config = function()
            local cmp = require "cmp"
            local luasnip = require "luasnip"
            luasnip.config.setup {}

            cmp.setup {
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                completion = { completeopt = "menu,menuone,noinsert" },
                mapping = cmp.mapping.preset.insert {
                    ["<C-n>"] = cmp.mapping.select_next_item(),
                    ["<C-p>"] = cmp.mapping.select_prev_item(),
                    ["<C-y>"] = cmp.mapping.confirm { select = true },
                    ["<C-e>"] = cmp.mapping.abort(),
                    ["<C-Space>"] = cmp.mapping.complete {},
                },
                sources = {
                    { name = "nvim_lsp" },
                    { name = "luasnip" },
                    { name = "path" },
                },
            }
        end
    },

{ "folke/todo-comments.nvim", event = "VimEnter", dependencies = { "nvim-lua/plenary.nvim" }, opts = { signs = false } },

--{ -- better around/inside selections and whatnot - these may be useful once I'm more used to all the keystrokes out there
--    "echasnovski/mini.nvim",
--    config = function()
--        require("mini.surround").setup()
--        require("mini.ai").setup{ n_lines = 500 }
--    end
--    },

    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        opts = {
            ensure_installed = {"python", "lua", "html", "c_sharp", "javascript", "typescript"},
            auto_install = true,
            highlight = { enable = true },
            indent = { enable = true },
        },
        config = function(_, opts)
            require("nvim-treesitter.configs").setup(opts)
        end,
    },

-- indentation lines
{ "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {}, },

-- comments
{ "numToStr/Comment.nvim", opts = {}, lazy = false },

} -- end of lazy setup

vim.cmd([[colorscheme monokai-nightasty]])

