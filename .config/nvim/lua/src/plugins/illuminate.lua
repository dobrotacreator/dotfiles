return {
	"RRethy/vim-illuminate",
	config = function()
		vim.cmd([[
            hi! IlluminatedWordText guibg=#3b3836
            hi! IlluminatedWordRead guibg=#3b3836
            hi IlluminatedWordWrite cterm=bold gui=bold guifg=#fe8019 guibg=#3b3836
        ]])
	end,
}
