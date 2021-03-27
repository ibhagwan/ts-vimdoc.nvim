# Introduction
A tree-sitter based markdown -> vimdoc conversion tool. The plugin is currently in sporadic development and will be undergoing api changes (once it has an API). If you use in CI, I recommend pinning the revision.

I created this plugin because I didn't want to generate vim help documentation from markdown sources. The current state of the plugin is that it "works" but the results are what I would consider "subpar".

I generally won't respond to issue/feature requests (yet), but will review pull requests.

### Ideas for contribution

- Tangle multiple markdown files (lspconfig README.md and CONFIG.md for example)
- (More) Intelligent line-wrapping
- Test and find errors in more complex markdown
- Convert nested codeblocks
- Convert numbered to '-' bulleted lists
- Add table of contents (optional)

### Usage as a plugin

If you use from within your *current* neovim session you first need to add
tree-sitter-markdown to your init.lua (or init.vim with a heredoc):

```lua
if pcall(require, "nvim-treesitter.parsers") then
  local parser_config = require "nvim-treesitter.parsers".get_parser_configs()

  parser_config.markdown = {
    install_info = {
      url = "https://github.com/ikatyang/tree-sitter-markdown",
      files = { "src/parser.c", "src/scanner.cc" },
    }
  }
end
```

Then install with `:TSInstallSync markdown`. Note, the parser may be unstable and crash your neovim instance. You can then create a Lua file (`example.lua`) with:

```lua
docgen = require('babelfish')
local metadata = {
	input_file='tests/README.md',
	output_file = 'tests/help.txt',
	project_name='lspconfig',
}
docgen.generate_readme(metadata)
```

and run with `:luafile example.lua` to generate your docs.

### Usage in CI

`./scripts/convert.sh` will convert ./tests/README.md to help.txt to show how to use a headless neovim instance for conversion. A provided dump of the parsed tree-sitter structure is shown.

Here is an example of using Babelfish in CI with github actions:

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
          git clone --depth 1 https://github.com/mjlbach/babelfish.nvim ~/.local/share/nvim/site/pack/vendor/start/babelfish.nvim
          git clone --depth 1 https://github.com/nvim-treesitter/nvim-treesitter ~/.local/share/nvim/site/pack/vendor/start/nvim-treesitter
          ln -s $(pwd) ~/.local/share/nvim/site/pack/vendor/start
      - name: Build parser
        run: |
          export PACKPATH=$HOME/.local/share/nvim/site
          ./build/nvim -u ~/.local/share/nvim/site/pack/vendor/start/babelfish.nvim/scripts/init.lua --headless -c 'TSInstallSync markdown' -c 'qa'
      - name: Generating docs
        run: |
          export PATH="${PWD}/build/:${PATH}"
          export PACKPATH=$HOME/.local/share/nvim/site
          ./build/nvim -u ~/.local/share/nvim/site/pack/vendor/start/babelfish.nvim/scripts/init.lua --headless -c 'luafile ./scripts/vimdocgen.lua' -c 'qa'
      - name: Commit changes
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          COMMIT_MSG: |
            [docgen] Update README.md
            skip-checks: true
        run: |
          git config user.email "actions@github"
          git config user.name "Github Actions"
          git remote set-url origin https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git
          git add README.md
          # Only commit and push if we have changes
          git diff --quiet && git diff --staged --quiet || (git commit -m "${COMMIT_MSG}"; git push origin HEAD:${GITHUB_REF})
```
