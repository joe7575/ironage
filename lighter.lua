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
	groups = {crumbly = 2, not_in_creative_inventory=1},
	sounds = default.node_sound_dirt_defaults(),
})

minetest.register_node("ironage:coal_lighter_burn", {
	tiles = {"ironage_lighter_burn.png"},
	
	after_place_node = function(pos)
		local meta = minetest.get_meta(pos)
		local playername = meta:get_string("playername")
		ironage.start_burner(pos, playername)
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
	groups = {crumbly = 2, not_in_creative_inventory=1},
	sounds = default.node_sound_dirt_defaults(),
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
	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		meta:set_string("playername", placer:get_player_name())
	end,
	is_ground_content = false,
	groups = {crumbly = 2, flammable = 2}, 
	sounds = default.node_sound_dirt_defaults(),
})

minetest.register_craft({
	output = 'ironage:lighter 2',
	recipe = {
		{'group:wood'},
		{'farming:straw'},
		{''},
	}
})
