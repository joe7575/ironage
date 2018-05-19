--[[

	Iron Age
	========

	v0.01 by JoSt

	Copyright (C) 2018 Joachim Stolberg
	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	2018-05-08  v0.01  first version

]]--

-- Load support for intllib.
local MP = minetest.get_modpath("ironage")
local S, NS = dofile(MP.."/intllib.lua")

ironage = {}

function ironage.swap_node(pos, name)
	minetest.swap_node(pos, {name = name})
	local node = minetest.registered_nodes[name]
	if node.on_construct then
		node.on_construct(pos)
	end
	if node.after_place_node then
		node.after_place_node(pos)
	end
end

function ironage.swap_nodes(pos1, pos2, name1, name2)
	for _,p in ipairs(minetest.find_nodes_in_area(pos1, pos2, name1)) do
		ironage.swap_node(p, name2)
	end
end

dofile(MP.."/charcoalpile.lua")
dofile(MP.."/coalburner.lua")
dofile(MP.."/meltingpot.lua")
dofile(MP.."/recipes.lua")

minetest.register_node("ironage:lighter_burn", {
	tiles = {"ironage_lighter_burn.png"},
	
	after_place_node = function(pos)
		ironage.start_pile(pos)
	end,
	
	on_timer = function(pos, elapsed)
		return ironage.keep_running_pile(pos)
	end,
	
	on_destruct = function(pos)
		ironage.stop_pile(pos)
	end,
	
	drop = "",
	light_source = 10,
	is_ground_content = false,
	groups = {cracky = 3},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("ironage:coal_lighter_burn", {
	tiles = {"ironage_lighter_burn.png"},
	
	after_place_node = function(pos)
		ironage.start_burner(pos)
	end,
	
	on_timer = function(pos, elapsed)
		return ironage.keep_running_burner(pos)
	end,
	
	on_destruct = function(pos)
		ironage.stop_burner(pos)
	end,
	
	drop = "",
	light_source = 10,
	is_ground_content = false,
	groups = {cracky = 3},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("ironage:lighter", {
	description = S("Lighter"),
	tiles = {"ironage_lighter.png"},
	on_ignite = function(pos, igniter)
		if minetest.find_node_near(pos, 1, "ironage:charcoal") then
			minetest.after(1, ironage.swap_node, pos, "ironage:coal_lighter_burn")
		else
			minetest.after(1, ironage.swap_node, pos, "ironage:lighter_burn")
		end
	end,
	is_ground_content = false,
	groups = {cracky = 3,flammable=2}, 
	sounds = default.node_sound_leaves_defaults(),
})

