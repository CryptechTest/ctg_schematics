local S = minetest.get_translator(minetest.get_current_modname())

schem_lib = {}

-- load files
local default_path = minetest.get_modpath("schem_lib")

dofile(default_path .. "/" .. "common.lua")
dofile(default_path .. "/" .. "functions.lua")
dofile(default_path .. "/" .. "serialization.lua")
dofile(default_path .. "/" .. "mtx.lua")
dofile(default_path .. "/" .. "api.lua")