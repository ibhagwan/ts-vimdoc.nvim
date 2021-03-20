A tree-sitter based markdown -> vimdoc conversion tool

# Usage

Run ./scripts/convert.sh, and it will convert ./tests/README.md to help.txt (harcoded for now). 

Packer is currently async only. Until there is a blocking install option I've added a 10s sleep to ensure all packages installed.

