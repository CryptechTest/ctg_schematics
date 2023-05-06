local S = minetest.get_translator(minetest.get_current_modname())

schemlib = {}

-- load files
local default_path = minetest.get_modpath("schemlib")

dofile(default_path .. DIR_DELIM .. "common.lua")
dofile(default_path .. DIR_DELIM .. "functions.lua")
dofile(default_path .. DIR_DELIM .. "serialization.lua")
dofile(default_path .. DIR_DELIM .. "mtx.lua")