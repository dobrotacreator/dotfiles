return {
	"ellisonleao/gruvbox.nvim",
	priority = 1000,
	config = function()
		require("gruvbox").setup({
			contrast = "hard",
		})
	end,
	init = function()
		vim.o.background = "dark"
		vim.cmd.colorscheme("gruvbox")
	end,
}
