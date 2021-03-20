#!/usr/bin/env bash
nvim -u scripts/init.lua -c ":PackerSync"  -c ":sleep 10" -c ":q" --headless
nvim -u scripts/init.lua -c ":TSInstallSync markdown" -c ":q" --headless
nvim -u scripts/init.lua -c ":luafile main.lua" -c ":q"  --headless
