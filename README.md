A tree-sitter based markdown -> vimdoc conversion tool

# Installation

Requires nvim-treesitter and tree-sitter-markdown installed and enabled for nvim. To enable tree-sitter-markdown, modify nvim-treesitter with the following patch:

```patch
diff --git a/lua/nvim-treesitter/parsers.lua b/lua/nvim-treesitter/parsers.lua
index 690348f..ffc5032 100644
--- a/lua/nvim-treesitter/parsers.lua
+++ b/lua/nvim-treesitter/parsers.lua
@@ -289,12 +289,12 @@ list.haskell = {
 }
 
 -- FIXME(vigoux): markdown is broken for now
--- list.markdown = {
---   install_info = {
---     url = "https://github.com/ikatyang/tree-sitter-markdown",
---     files = { "src/parser.c", "src/scanner.cc" },
---   }
--- }
+list.markdown = {
+  install_info = {
+    url = "https://github.com/ikatyang/tree-sitter-markdown",
+    files = { "src/parser.c", "src/scanner.cc" },
+  }
+}
 
 list.toml = {
   install_info = {
```
