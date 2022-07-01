#!/bin/sh
set -eu
trap 'echo "EXIT detected with exit status $?"' EXIT

# script working directory
BASEDIR=$(cd "$(dirname "$0")" ; pwd -P)

tmp_dir=/tmp/ts-vimdoc.nvim
tmp_rtp="${tmp_dir}/nvim/site/pack/vendor/start"
plug_dir="${BASEDIR}/../../ts-vimdoc.nvim"

# If you're not using nightly built
nightly=/shared/bhagwan/Applications/nvim.appimage
nvim=nvim

usage() {
    echo "Usage $0: <input_file> <output_file> <project_name>"
}

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

if [ "$#" -ne 3 ]; then
    usage;
    exit 1
fi

if [ -x ${nightly} ]; then
    nvim=${nightly}
    echo "Using nightly build in ${nvim}"
fi

download_plugin "nvim-treesitter" "nvim-treesitter" 

# if exists, link to local folder so we can test local changes
if [ -d "${plug_dir}" ]; then
    echo "Using local plugin ts-vimdoc.nvim from '${plug_dir}'"
    ln -fs ${plug_dir} ${tmp_rtp}
else
    download_plugin "ibhagwan" "ts-vimdoc.nvim"
fi

# install the markdown parsers
HOME=/tmp ${nvim} --headless -u ${tmp_rtp}/ts-vimdoc.nvim/scripts/init.lua -c "TSUpdateSync markdown" -c "TSUpdateSync markdown_inline" -c "qa"

# finally, generate the vimdoc
HOME=/tmp ${nvim} --headless -u ${tmp_rtp}/ts-vimdoc.nvim/scripts/init.lua -c "lua require('ts-vimdoc').docgen({input_file='${1}', output_file = '${2}', project_name='${3}'})" -c "qa"

echo "\nDone."
