return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	opts = {
		options = { theme = "gruvbox-material" },
		sections = {
			lualine_c = {
				{
					"filename",
					file_status = true,
					path = 1, -- 0 = just filename, 1 = relative path, 2 = absolute path
				},
			},
		},
	},
}
