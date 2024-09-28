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
		-- format_on_save = {
		-- 	lsp_format = "fallback",
		-- 	timeout_ms = 1000,
		-- },
		formatters_by_ft = {
			lua = { "stylua" },
			-- python = { "isort", "black" },
			python = { "ruff_fix", "ruff_format" },
		},
	},
}
