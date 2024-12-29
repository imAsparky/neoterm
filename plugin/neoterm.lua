-- plugin/neoterm.lua
if vim.g.loaded_neoterm then
	return
end
vim.g.loaded_neoterm = true

-- Create base terminal command
vim.api.nvim_create_user_command("Neoterm", function()
	require("neoterm.terminal").toggle()
end, {
	desc = "Open floating terminal",
})

-- Create command to set venv name
vim.api.nvim_create_user_command("NeotermSetVenv", function(opts)
	require("neoterm.config").set_venv(opts.args)
end, {
	desc = "Set virtual environment directory name",
	nargs = 1,
})
