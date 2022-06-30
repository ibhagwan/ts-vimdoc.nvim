# Introduction
A tree-sitter based markdown -> vimdoc conversion tool.

Originally, I believe, this plugin was written by
[@mizlan](https://github.com/mizlan/babelfish.nvim), it was then forked and
modified by @mjlbach, the original version required the markdown parser from
@ikatyang
[tree-sitter-markdown](https://github.com/ikatyang/tree-sitter-markdown).

I was looking for a markdown -> vimdoc tool that wasn't dependent on anything
but neovim (+treesitter) and came across it but the code was very rudimentary
and didn't work on the [fzf-lua
README.md](https://github.com/ibhagwan/fzf-lua/blob/main/README.md) so I
modified the logic quite substantially.

Since then @MDeiml wrote
[tree-sitter-markdown](https://github.com/MDeiml/tree-sitter-markdown) which
is now split into 2 different parsers `markdown` and `markdown_inline`, now
the default parsers for neovim-treesitter.

[@mjlbach is no longer associated with
neovim](https://www.reddit.com/r/neovim/comments/vd0vim/anyone_know_whats_going_on_with_mjldach/)
and also deleted all his neovim repositories (the former upstream repo) so it
made very little sense to keep the fork dependency.

There is much to be desired when it comes to optimizing this code, cleaning up
the API, having proper unit testing, etc but it's not on my priority list, as
long as it keeps generating the vimdoc for
[fzf-lua](https://github.com/ibhagwan/fzf-lua) I'm ok with it, nevertheless
feel free to open issues if you wish and maybe someday I'll invest more time
in this plugin.


### Usage as a plugin

If you use from within your *current* neovim session you first need to add
tree-sitter-markdown to your init.lua (or init.vim with a heredoc):

```lua
require'nvim-treesitter.configs'.setup {
  ensure_installed = { "markdown", "markdown_inline" },
  ...
}
```

Then install with `:TSUpdateSync`.

To generate vimdoc run:

```lua
require('babelfish').generate_readme({
	input_file='README.md',
	output_file = 'doc/babelfish.txt',
	project_name='babelfish',
})
```

### Usage in CI

`./scripts/convert.sh` will convert download nvim-treesitter into a neovim 
minimal environment under `/tmp/babelfish`  and convert README.md into
./doc/babelfish.txt.

Here is an example of using Babelfish in CI with github actions:

> **Note:** For the below to work you need to replace `doc/babelfish.txt`
> (twice) and set `project_name=<your project>`.

```yaml
name: vimdoc

on:
  push:
    branches:
      - master

jobs:
  vimdocgen:
    runs-on: [ubuntu-latest]
    steps:
      - uses: actions/checkout@v2
      - run: date +%F > todays-date
      - name: Restore cache for today's nightly.
        uses: actions/cache@v2
        with:
          path: build
          key: ${{ runner.os }}-appimage-${{ hashFiles('todays-date') }}

      - name: Setup neovim nightly and install plugins
        run: |
          test -d build || {
            mkdir -p build
            wget https://github.com/neovim/neovim/releases/download/nightly/nvim.appimage
            chmod +x nvim.appimage
            mv nvim.appimage ./build/nvim
          }
          mkdir -p ~/.local/share/nvim/site/pack/vendor/start
          git clone --depth 1 https://github.com/ibhagwan/babelfish.nvim ~/.local/share/nvim/site/pack/vendor/start/babelfish.nvim
          git clone --depth 1 https://github.com/nvim-treesitter/nvim-treesitter ~/.local/share/nvim/site/pack/vendor/start/nvim-treesitter
          ln -s $(pwd) ~/.local/share/nvim/site/pack/vendor/start || true
      - name: Build parser
        run: |
          export PACKPATH=$HOME/.local/share/nvim/site
          ./build/nvim --headless -u ~/.local/share/nvim/site/pack/vendor/start/babelfish.nvim/scripts/init.lua -c "TSUpdateSync markdown" -c "TSUpdateSync markdown_inline" -c "qa"
      - name: Generating docs
        run: |
          export PATH="${PWD}/build/:${PATH}"
          export PACKPATH=$HOME/.local/share/nvim/site
          ./build/nvim --headless -u ~/.local/share/nvim/site/pack/vendor/start/babelfish.nvim/scripts/init.lua  -c "lua require('babelfish').generate_readme({input_file='README.md', output_file='doc/babelfish.txt', project_name='babelfish'})" -c "qa"
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
          git add doc/babelfish.txt
          # Only commit and push if we have changes
          git diff --quiet && git diff --staged --quiet || (git commit -m "${COMMIT_MSG}"; git push origin HEAD:${GITHUB_REF})
```
