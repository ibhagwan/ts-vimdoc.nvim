#!/bin/sh

tmp_dir=/tmp/babelfish
tmp_rtp="${tmp_dir}/nvim/site/pack/vendor/start"
nightly=/shared/bhagwan/Applications/nvim.appimage
nvim=nvim

if [ -x ${nightly} ]; then
    nvim=${nightly}
    echo "Using nightly build in ${nvim}"
fi

download_plugin() {
    repo="https://github.com/${1}/${2}"
    folder="${tmp_rtp}/${2}"
    if [ ! -d $folder ]; then
        echo "Downloading '${repo}' into '${folder}..."
        git clone --depth 1 ${repo} ${folder}
    else
        echo "Updating '${repo}'..."
        git -C "${folder}" pull --rebase
    fi
}

download_plugin "nvim-treesitter" "nvim-treesitter" 

# link to local folder so we can test local changes
# download_plugin "ibhagwan" "babelfish.nvim"
if [ ! -L "${tmp_rtp}/babelfish.nvim" ]; then
    echo "Linking '$(pwd)' to '${tmp_rtp}/babelfish.nvim'..."
    ln -s $(pwd) ${tmp_rtp}
fi

# this installs all parsers found in 'ensure_installed'
HOME=/tmp ${nvim} --headless -u scripts/init.lua -c "TSUpdateSync markdown" -c "TSUpdateSync markdown_inline" -c "q"

# finally, generate the vimdoc
HOME=/tmp ${nvim} --headless -u scripts/init.lua -c "lua require('babelfish').generate_readme({input_file='README.md', output_file = 'doc/babelfish.txt', project_name='babelfish'})" -c "q"

echo "\nDone."
