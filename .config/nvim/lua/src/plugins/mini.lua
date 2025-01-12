return {
	"echasnovski/mini.nvim",
	version = false,
	config = function()
		require("mini.bracketed").setup() -- Go forward/backward with square brackets
		require("mini.comment").setup() -- Comment lines
		require("mini.files").setup({ -- Navigate and manipulate file system
			options = {
				permanent_delete = false,
			},
			windows = {
				preview = true,
			},
		})
        vim.keymap.set("n", "<leader><Tab>", ":lua MiniFiles.open(vim.api.nvim_buf_get_name(0))<CR>")
		require("mini.hipatterns").setup({ -- Highlight patterns in text
			highlighters = {
				fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
				hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
				todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
				note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
				hex_color = require("mini.hipatterns").gen_highlighter.hex_color(),
			},
		})
		require("mini.icons").setup() -- Icon provider
		require("mini.indentscope").setup() -- Visualize and work with indent scope
		require("mini.pairs").setup() -- Autopairs

		local go_in_plus = function()
			for _ = 1, vim.v.count1 do
				MiniFiles.go_in({ close_on_file = true })
			end
		end

		vim.api.nvim_create_autocmd("User", {
			pattern = "MiniFilesBufferCreate",
			callback = function(args)
				local map_buf = function(lhs, rhs)
					vim.keymap.set("n", lhs, rhs, { buffer = args.data.buf_id })
				end

				map_buf("<CR>", go_in_plus)
				map_buf("<Left>", MiniFiles.go_out)
				map_buf("<Esc>", MiniFiles.close)
			end,
		})
	end,
}
