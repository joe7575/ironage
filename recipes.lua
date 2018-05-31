--[[

	Iron Age
	========

	Copyright (C) 2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

]]--

ironage.register_recipe({
	output = "default:obsidian", 
	recipe = {"default:cobble"}, 
	heat = 5,
	time = 4,
})

ironage.register_recipe({
	output = "default:steel_ingot 4", 
	recipe = {"default:coal_lump", "default:iron_lump", "default:iron_lump", "default:iron_lump"}, 
	heat = 4,
	time = 8,
})

minetest.clear_craft({output = "default:steel_ingot"})

