local S = minetest.get_translator(minetest.get_current_modname())

ctg_deepspace = {}

-- load files
local default_path = minetest.get_modpath("ctg_deepspace")

dofile(default_path .. DIR_DELIM .. "cell.lua")
--dofile(default_path .. DIR_DELIM .. "functions.lua")
dofile(default_path .. DIR_DELIM .. "mapgen.lua")
