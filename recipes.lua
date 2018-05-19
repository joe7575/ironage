--[[

	Iron Age
	========

	Copyright (C) 2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

]]--

-- Load support for intllib.
local MP = minetest.get_modpath("ironage")
local S, NS = dofile(MP.."/intllib.lua")

ironage.register_recipe({
	output = "default:obsidian", 
	recipe = {"default:cobble"}, 
	heat = 4,
})

ironage.register_recipe({
	output = "default:gold_ingot", 
	recipe = {"default:copper_lump", "default:mese_crystal_fragment"}, 
	heat = 4
})

ironage.register_recipe({
	output = "default:gold_ingot", 
	recipe = {"default:gold_lump"}, 
	heat = 4
})

ironage.register_recipe({
	output = "default:steel_ingot", 
	recipe = {"default:iron_lump"}, 
	heat = 4
})
minetest.clear_craft({output = "default:steel_ingot"})

