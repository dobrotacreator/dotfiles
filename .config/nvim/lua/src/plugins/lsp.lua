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
				if client and client.server_capabilities.documentHighlightProvider then
					local highlight_augroup = vim.api.nvim_create_augroup("lsp-highlight", { clear = false })
					vim.opt.updatetime = 100
					vim.cmd([[
                        hi! LspReferenceRead guibg=#3b3836
                        hi! LspReferenceText guibg=#3b3836
                        hi! LspReferenceWrite guibg=#3b3836
                    ]])

					vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
						buffer = event.buf,
						group = highlight_augroup,
						callback = vim.lsp.buf.document_highlight,
					})

					vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
						buffer = event.buf,
						group = highlight_augroup,
						callback = vim.lsp.buf.clear_references,
					})

					vim.api.nvim_create_autocmd("LspDetach", {
						group = vim.api.nvim_create_augroup("lsp-detach", { clear = true }),
						callback = function(event2)
							vim.lsp.buf.clear_references()
							vim.api.nvim_clear_autocmds({ group = "lsp-highlight", buffer = event2.buf })
						end,
					})
				end

				if client and (client.name == "ruff_lsp" or client.name == "pyright") then
					vim.api.nvim_create_autocmd("BufWritePre", {
						callback = function()
							if vim.bo.ft == "python" then
								vim.lsp.buf.code_action({
									context = {
										diagnostics = {},
										only = { "source.fixAll.ruff" },
									},
									apply = true,
								})
							end
						end,
					})
					map("<space>ca", function()
						vim.lsp.buf.code_action({
							context = {
								diagnostics = {},
								only = {
									"source.organizeImports",
								},
							},
							apply = true,
						})
					end)
				end

				if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
					map("<leader>ih", function()
						vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
					end)
				end
			end,
		})

		local capabilities = vim.lsp.protocol.make_client_capabilities()
		capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

		local servers = {
			buf = {
				filetypes = { "proto" },
			},
			clangd = {
				filetypes = { "c", "cpp", "objc", "objcpp" },
			},
			gopls = {},
			pyright = {},
			ruff_lsp = {},
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
			"stylua",
			"autopep8",
		})
		require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

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
