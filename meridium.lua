--[[

	Iron Age
	========

	Copyright (C) 2018 Joachim Stolberg
    Based on mods/default/tools.lua
	
	LGPLv2.1+
	See LICENSE.txt for more information

]]--

-- Load support for intllib.
local MP = minetest.get_modpath("ironage")
local S, NS = dofile(MP.."/intllib.lua")


minetest.register_craftitem("ironage:meridium_ingot", {
	description = "Meridium Ingot",
	inventory_image = "ironage_meridium_ingot.png",
})


minetest.register_tool("ironage:pick_meridium", {
	description = S("Meridium Pickaxe"),
	inventory_image = "ironage_meridiumpick.png",
	tool_capabilities = {
		full_punch_interval = 1.0,
		max_drop_level=1,
		groupcaps={
			cracky = {times={[1]=4.00, [2]=1.60, [3]=0.80}, uses=30, maxlevel=2},
		},
		damage_groups = {fleshy=4},
	},
	sound = {breaks = "default_tool_breaks"},
	light_source = 12,
})

minetest.register_tool("ironage:shovel_meridium", {
	description = S("Meridium Shovel"),
	inventory_image = "ironage_meridiumshovel.png",
	wield_image = "ironage_meridiumshovel.png^[transformR90",
	tool_capabilities = {
		full_punch_interval = 1.1,
		max_drop_level=1,
		groupcaps={
			crumbly = {times={[1]=1.50, [2]=0.90, [3]=0.40}, uses=40, maxlevel=2},
		},
		damage_groups = {fleshy=3},
	},
	sound = {breaks = "default_tool_breaks"},
	light_source = 12,
})

minetest.register_tool("ironage:axe_meridium", {
	description = S("Meridium Axe"),
	inventory_image = "ironage_meridiumaxe.png",
	tool_capabilities = {
		full_punch_interval = 1.0,
		max_drop_level=1,
		groupcaps={
			choppy={times={[1]=2.50, [2]=1.40, [3]=1.00}, uses=20, maxlevel=2},
		},
		damage_groups = {fleshy=4},
	},
	sound = {breaks = "default_tool_breaks"},
	light_source = 12,
})

minetest.register_tool("ironage:sword_meridium", {
	description = S("Meridium Sword"),
	inventory_image = "ironage_meridiumsword.png",
	tool_capabilities = {
		full_punch_interval = 0.8,
		max_drop_level=1,
		groupcaps={
			snappy={times={[1]=2.5, [2]=1.20, [3]=0.35}, uses=30, maxlevel=2},
		},
		damage_groups = {fleshy=6},
	},
	sound = {breaks = "default_tool_breaks"},
	light_source = 12,
})

minetest.register_craft({
	output = 'ironage:pick_meridium',
	recipe = {
		{'ironage:meridium_ingot', 'ironage:meridium_ingot', 'ironage:meridium_ingot'},
		{'', 'group:stick', ''},
		{'', 'group:stick', ''},
	}
})

minetest.register_craft({
	output = 'ironage:shovel_meridium',
	recipe = {
		{'ironage:meridium_ingot'},
		{'group:stick'},
		{'group:stick'},
	}
})

minetest.register_craft({
	output = 'ironage:axe_meridium',
	recipe = {
		{'ironage:meridium_ingot', 'ironage:meridium_ingot'},
		{'ironage:meridium_ingot', 'group:stick'},
		{'', 'group:stick'},
	}
})

minetest.register_craft({
	output = 'ironage:sword_meridium',
	recipe = {
		{'ironage:meridium_ingot'},
		{'ironage:meridium_ingot'},
		{'group:stick'},
	}
})

ironage.register_recipe({
	output = "ironage:meridium_ingot", 
	recipe = {"default:steel_ingot", "default:mese_crystal_fragment"}, 
	heat = 4,
	time = 3,
})
