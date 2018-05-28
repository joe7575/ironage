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
	heat = 5,
	time = 4,
})

ironage.register_recipe({
	output = "default:bronze_ingot 4", 
	recipe = {"default:tin_ingot", "default:copper_ingot", "default:copper_ingot", "default:copper_ingot"}, 
	heat = 2,
	time = 8,
})

ironage.register_recipe({
	output = "default:steel_ingot", 
	recipe = {"default:coal_lump", "default:iron_lump", "default:iron_lump", "default:iron_lump"}, 
	heat = 4,
	time = 8,
})

minetest.clear_craft({output = "default:steel_ingot"})
minetest.clear_craft({output = "default:bronze_ingot"})

