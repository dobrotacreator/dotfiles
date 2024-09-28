return {
	"echasnovski/mini.nvim",
	version = false,
	config = function()
		require("mini.bracketed").setup() -- Go forward/backward with square brackets
		require("mini.comment").setup() -- Comment lines
		require("mini.files").setup() -- Navigate and manipulate file system
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
	end,
}
