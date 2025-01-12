return {
	"neovim/nvim-lspconfig",
	dependencies = {
		{ "williamboman/mason.nvim", config = true },
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		{ "j-hui/fidget.nvim", opts = {} },
		{ "folke/neodev.nvim", opts = {} },
	},

	config = function()
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
			callback = function(event)
				local map = function(keys, func)
					vim.keymap.set("n", keys, func, { buffer = event.buf })
				end
				map("gd", require("telescope.builtin").lsp_definitions)
				map("gr", require("telescope.builtin").lsp_references)
				map("gi", require("telescope.builtin").lsp_implementations)
				map("gD", vim.lsp.buf.declaration)
				map("<leader>rn", vim.lsp.buf.rename)
				map("<leader>ca", vim.lsp.buf.code_action)
				map("<leader>sh", vim.lsp.buf.signature_help)
				map("K", vim.lsp.buf.hover)

				local client = vim.lsp.get_client_by_id(event.data.client_id)
				if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
					map("<leader>ih", function()
						vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
					end)
				end
				if client and client.name == "clangd" then
					map("gh", "<cmd>ClangdSwitchSourceHeader<CR>")
				end
			end,
		})

		local servers = {
			buf = {
				filetypes = { "proto" },
			},
			clangd = {
				filetypes = { "c", "cpp", "objc", "objcpp" },
			},
			glslls = {
				cmd = { "glslls", "--stdin", "--target-env=opengl" },
			},
			pyright = {
				settings = {
					python = {
						analysis = {
							diagnosticMode = "workspace",
							typeCheckingMode = "basic",
						},
					},
				},
			},
			ruff = {
				trace = "messages",
				init_options = {
					settings = {
						logLevel = "debug",
					},
				},
			},
			lua_ls = {
				settings = {
					Lua = {
						completion = {
							callSnippet = "Replace",
						},
					},
				},
			},
		}
		require("mason").setup()

		local ensure_installed = vim.tbl_keys(servers or {})
		vim.list_extend(ensure_installed, {
			"ts_ls",
			"eslint",
			"html",
			"cssls",
			"stylua",
			"gopls",
		})
		require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

		local capabilities = vim.lsp.protocol.make_client_capabilities()
		capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())
		require("mason-lspconfig").setup({
			handlers = {
				function(server_name)
					local server = servers[server_name] or {}
					server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
					require("lspconfig")[server_name].setup(server)
				end,
			},
		})
	end,
}
