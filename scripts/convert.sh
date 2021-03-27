# rm -rf /tmp/babelfish

# # git clone --depth 1 https://github.com/mjlbach/babelfish.nvim /tmp/babelfish/nvim/site/pack/vendor/start/babelfish.nvim
# git clone --depth 1 https://github.com/nvim-treesitter/nvim-treesitter /tmp/babelfish/nvim/site/pack/vendor/start/nvim-treesitter
# ln -s $(pwd) /tmp/babelfish/nvim/site/pack/vendor/start

# HOME=/tmp nvim -u scripts/init.lua -c "TSInstallSync markdown" -c "q"  --headless

HOME=/tmp nvim -u scripts/init.lua -c "lua require('babelfish').generate_readme({input_file='tests/README.md', output_file = 'tests/help.txt', project_name='lspconfig'})" -c "q"  --headless
