return {
	"kndndrj/nvim-dbee",
	dependencies = {
		"MunifTanjim/nui.nvim",
	},
	build = function()
		-- Install tries to automatically detect the install method.
		-- if it fails, try calling it with one of these parameters:
		--    "curl", "wget", "bitsadmin", "go"
		require("dbee").install()
	end,
	config = function()
		local opts = require("dbee.config").default
		opts.drawer.disable_help = true
		require("dbee").setup(opts)
        vim.keymap.set("n", "<leader>db", ":Dbee<CR>")
	end,
}
