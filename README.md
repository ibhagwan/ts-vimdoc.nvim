## Introduction

A tree-sitter based markdown -> vimdoc conversion tool.

Originally, this plugin was written by @mjlbach and was named `babelfish.nvim`,
the original version required the markdown parser from @ikatyang
[tree-sitter-markdown](https://github.com/ikatyang/tree-sitter-markdown).

I was looking for a markdown -> vimdoc tool that wasn't dependent on anything
but neovim (+treesitter) and came across it but the code was very rudimentary
and didn't work on the [fzf-lua
README.md](https://github.com/ibhagwan/fzf-lua/blob/main/README.md) so I
modified the logic quite substantially.

Since then @MDeiml wrote
[tree-sitter-markdown](https://github.com/MDeiml/tree-sitter-markdown) which
is now split into 2 different parsers `markdown` and `markdown_inline`, now
the default parsers for neovim-treesitter, this required a total makeover of
the original recursion logic.

@mjlbach is no longer associated with neovim and also deleted all of his neovim
repositories (the former upstream repo) so it made very little sense to keep the
fork dependency or the old name which makes it quite obscure and harder to find.

There is much to be desired when it comes to optimizing this code, cleaning up
the API, having proper unit testing, etc, but it's not high on my priority list,
as long as it doesn't croak while generating a vimdoc, I'm content, nevertheless
feel free to open issues and I will address them when I have time.

I personally recommend also trying out
[`kdheepak/panvimdoc`](https://github.com/kdheepak/panvimdoc), it uses
`pandoc` style markdown and can also be set as a github CI action for the
"fire and forget" approach.


### Usage as a plugin

> **NOTE: CURRENTLY, REQUIRES USING NEOVIM-NIGHTLY (>=0.8)**

If you use from within your *current* neovim session you need to install
[`nvim-treesitter`](https://github.com/nvim-treesitter/nvim-treesitter) and
both markdown parsers `markdown` and `markdown_inline` (will be downloaded
automatically by the treesitter plugin from
[`tree-sitter-markdown`](https://github.com/MDeiml/tree-sitter-markdown)):

Use your favorite plugin manager to install `nvim-treesitter` with the below
configuration:

```lua
require'nvim-treesitter.configs'.setup {
  ensure_installed = { "markdown", "markdown_inline" },
}
```

And make sure both parsers are installed by running:
```
:TSUpdateSync markdown
:TSUpdateSync markdown_inline
```

To generate vimdoc run:
```lua
require('ts-vimdoc').docgen({
	input_file='README.md',
	output_file = 'doc/ts-vimdoc.txt',
	project_name='ts-vimdoc',
})
```

### Usage as standalone

If you don't wish to configure treesitter you can use the supplied
`scripts/docgen.sh`, the script will create a temporary environment under
`/tmp/ts-vimdoc.nvim` and run a neovim headless instance to perform the
vimdoc conversion.

The script requires 3 parameters (same as the `docgen` function): input file,
output file and project name (to be used for generating headers):
```sh
❯ ./scripts/docgen.sh README.md doc/ts-vimdoc.txt ts-vimdoc
```

If you wish to make local changes to this project `docgen.sh` will link your
local `ts-vimdoc.nvim` plugin as long as it's located in the same subtree of
the plugin you wish to generate, for example, this is how I use it to generate
fzf-lua vimdoc, I have both plugins downloaded in the same folder:

```
❯ ls -l
drwxr-xr-x - bhagwan bhagwan 2022-06-30 20:47 fzf-lua
drwxr-xr-x - bhagwan bhagwan 2022-07-01 06:14 ts-vimdoc.nvim
```
I can then run `docgen.sh` from inside the `fzf-lua` folder:
```sh
❯ ./ts-vimdoc.nvim/scripts/docgen.sh ./fzf-lua/README.md ./fzf-lua/doc/fzf-lua.txt fzf-lua
```

Or from inside the `fzf-lua` folder:
```sh
❯ cd fzf-lua
❯ ../ts-vimdoc.nvim/scripts/docgen.sh README.md doc/fzf-lua.txt fzf-lua
```

### Usage in CI

Below is an example of using ts-vimdoc in CI with github action with
[fzf-lua](https://github.com/ibhagwan/fzf-lua):

> **TO USE WITH YOUR PROJECT:**
> - Set the correct branch, currently set to `main` (line 6)
> - Replace `doc/fzf-lua.txt` with `<output path of your vimdoc>` (lines 40,51)
> - Replace `project_name='fzf-lua'` with `project_name='<your project>'` (line 40)

```yaml
name: vimdoc

on:
  push:
    branches:
      - main

jobs:
  vimdocgen:
    runs-on: [ubuntu-latest]
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
      - run: date +%F > todays-date
      - name: Restore cache for today's nightly.
        uses: actions/cache@v3
        with:
          path: build
          key: ${{ runner.os }}-appimage-${{ hashFiles('todays-date') }}
      - name: Install FUSE
        run: sudo apt-get install -y libfuse2
      - name: Setup neovim nightly and install plugins
        run: |
          test -d build || {
            mkdir -p build
            wget https://github.com/neovim/neovim/releases/download/nightly/nvim.appimage
            chmod +x nvim.appimage
            mv nvim.appimage ./build/nvim
          }
          mkdir -p ~/.local/share/nvim/site/pack/vendor/start
          git clone --depth 1 https://github.com/ibhagwan/ts-vimdoc.nvim ~/.local/share/nvim/site/pack/vendor/start/ts-vimdoc.nvim
          git clone --depth 1 https://github.com/nvim-treesitter/nvim-treesitter ~/.local/share/nvim/site/pack/vendor/start/nvim-treesitter
      - name: Build parser
        run: |
          export PACKPATH=$HOME/.local/share/nvim/site
          ./build/nvim --headless -u ~/.local/share/nvim/site/pack/vendor/start/ts-vimdoc.nvim/scripts/init.lua -c "TSUpdateSync markdown" -c "TSUpdateSync markdown_inline" -c "qa"
      - name: Generating docs
        run: |
          export PATH="${PWD}/build/:${PATH}"
          export PACKPATH=$HOME/.local/share/nvim/site
          ./build/nvim --headless -u ~/.local/share/nvim/site/pack/vendor/start/ts-vimdoc.nvim/scripts/init.lua  -c "lua require('ts-vimdoc').docgen({input_file='README.md', output_file='doc/fzf-lua.txt', project_name='fzf-lua', version='For Neovim >= 0.8.0'})" -c "qa"
      - name: Commit changes
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          COMMIT_MSG: |
            [docgen] CI: autogenerate vimdoc
            skip-checks: true
        run: |
          git config user.email "actions@github"
          git config user.name "Github Actions"
          git remote set-url origin https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git
          git add doc/fzf-lua.txt
          # Only commit and push if we have changes
          git diff --quiet && git diff --staged --quiet || (git commit -m "${COMMIT_MSG}"; git push origin HEAD:${GITHUB_REF})
```
