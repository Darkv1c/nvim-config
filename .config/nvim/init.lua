-- [[ Leader Key ]]
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.relativenumber = true
vim.opt.laststatus = 0
vim.opt.wrap = true
vim.opt.breakindent = true
vim.opt.linebreak = true
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- [[ Lazy.nvim Bootstrap ]]
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- [[ Plugins ]]
-- Load plugins based on NVIM_PROFILE environment variable
local profile = vim.env.NVIM_PROFILE or "default"

local profile_imports = {
	default = {
		{ import = "plugins.core" },
	},
	study = {
		{ import = "plugins.core" },
		{ import = "plugins.study" },
	},
	work = {
		{ import = "plugins.core" },
		{ import = "plugins.work" },
	},
}

require("lazy").setup(profile_imports[profile] or profile_imports.default)

-- [[ UI Settings ]]
vim.cmd("colorscheme lunaperche")
vim.opt.fillchars:append({ vert = "▏" }) -- Delgada ▏ o cambia por "│"
vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#3b4261", bg = "NONE" })

-- Transparent backgrounds only work properly with termguicolors
if vim.o.termguicolors then
	vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
	vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
	vim.api.nvim_set_hl(0, "Pmenu", { bg = "none" })
end

-- [[ General Options ]]
vim.o.number = true
vim.o.relativenumber = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.list = true
vim.o.confirm = true

-- Sync clipboard after UIEnter to reduce startup time
vim.api.nvim_create_autocmd("UIEnter", {
	callback = function()
		vim.o.clipboard = "unnamedplus"
	end,
})

-- [[ Keymaps ]]
vim.keymap.set("t", "<leader><Esc>", "<C-\\><C-n>")
-- Window navigation
vim.keymap.set("n", "<leader>h", "<C-w>h", { noremap = true })
vim.keymap.set("n", "<leader>j", "<C-w>j", { noremap = true })
vim.keymap.set("n", "<leader>k", "<C-w>k", { noremap = true })
vim.keymap.set("n", "<leader>l", "<C-w>l", { noremap = true })

-- Custom mappings
vim.keymap.set("n", "ñ", ";", { noremap = true })

-- Diagnostics (errors and warnings)
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic message (float)" })
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic list (loclist)" })
vim.diagnostic.config({ virtual_text = true, virtual_lines = true })

-- Copilot keymaps
vim.keymap.set("i", "<leader><leader>", "copilot#Accept()", {
	expr = true,
	silent = true,
	replace_keycodes = false,
})
vim.keymap.set("i", "<leader><Tab>", "copilot#Next()", {
	expr = true,
	silent = true,
	replace_keycodes = false,
})
vim.keymap.set("i", "<leader><S-Tab>", "copilot#Previous()", {
	expr = true,
	silent = true,
	replace_keycodes = false,
})

-- [[ Autocommands ]]
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	callback = function()
		vim.hl.on_yank()
	end,
})
vim.api.nvim_create_autocmd('LspAttach', {
	group = vim.api.nvim_create_augroup('LspAttach', { clear = false }),
	callback = function(event)
		local opts = { buffer = event.buf }
		vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
	end,
})
vim.api.nvim_create_autocmd('LspAttach', {
	callback = function(ev)
		vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = ev.buf })
	end,
})
vim.api.nvim_create_autocmd('LspAttach', {
	callback = function(ev)
		vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = ev.buf })
	end,
})

-- [[ User Commands ]]
vim.api.nvim_create_user_command("GitBlameLine", function()
	local line_number = vim.fn.line(".")
	local filename = vim.api.nvim_buf_get_name(0)
	print(vim.fn.system({ "git", "blame", "-L", line_number .. ",+1", filename }))
end, { desc = "Print the git blame for the current line" })

-- [[ Optional Packages ]]
vim.cmd("packadd! nohlsearch")
