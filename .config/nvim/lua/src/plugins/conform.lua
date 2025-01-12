return {
	"stevearc/conform.nvim",
	lazy = false,
	keys = {
		{
			"<leader><leader>",
			function()
				require("conform").format({ async = true, lsp_fallback = true })
			end,
			mode = "",
		},
	},
	opts = {
		notify_on_error = true,
		formatters_by_ft = {
			lua = { "stylua" },
			python = { "ruff_fix", "ruff_format" },
		},
	},
}
