--[[

	Iron Age
	========

	Copyright (C) 2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

]]--

local PILE_BURN_TIME = 100

local function num_wood(pos)
	local pos1 = {x=pos.x-1, y=pos.y, z=pos.z-1}
	local pos2 = {x=pos.x+1, y=pos.y+2, z=pos.z+1}
	local nodes = minetest.find_nodes_in_area(pos1, pos2, "group:wood")
	return #nodes
end

local function num_dirt(pos)
	local pos1 = {x=pos.x-2, y=pos.y-1, z=pos.z-2}
	local pos2 = {x=pos.x+2, y=pos.y+3, z=pos.z+2}
	local nodes = minetest.find_nodes_in_area(pos1, pos2, {"default:dirt", "default:dirt_with_grass", 
			"default:dirt_with_dry_grass", "default:dirt_with_snow", "ironage:dirt_with_ash"})
	return #nodes
end

local function make_dirt_with_ash(pos)
	pos.y = pos.y - 1
	if string.find(minetest.get_node(pos).name, "default:dirt") then
		minetest.swap_node(pos, {name = "ironage:dirt_with_ash"})
	end
	pos.y = pos.y + 1
end

local function make_dirt_with_dry_grass(pos)
	local pos1 = {x=pos.x-2, y=pos.y+3, z=pos.z-2}
	local pos2 = {x=pos.x+2, y=pos.y+3, z=pos.z+2}
	for _,p in ipairs(minetest.find_nodes_in_area(pos1, pos2, "default:dirt_with_grass")) do
		minetest.swap_node(p, {name = "default:dirt_with_dry_grass"})
	end
end

local function start_smoke(pos)
	local meta = minetest.get_meta(pos)
	pos = {x=pos.x, y=pos.y+3.6, z=pos.z}
	local id = meta:get_int("smoke")
	local above = minetest.get_node(pos).name

	if id ~= 0 then
		minetest.delete_particlespawner(id)
		meta:set_int("smoke", nil)
	end

	if above == "air" then
		id = minetest.add_particlespawner({
			amount = 4, time = 0, collisiondetection = true,
			minpos = {x=pos.x-0.25, y=pos.y+0.1, z=pos.z-0.25},
			maxpos = {x=pos.x+0.25, y=pos.y+5, z=pos.z+0.25},
			minvel = {x=-0.2, y=0.3, z=-0.2}, maxvel = {x=0.2, y=1, z=0.2},
			minacc = {x=0,y=0,z=0}, maxacc = {x=0,y=0.5,z=0},
			minexptime = 1, maxexptime = 3,
			minsize = 6, maxsize = 12,
			texture = "ironage_smoke.png",
		})
		meta:set_int("smoke", id)
	end
end

local function stop_smoke(pos)
	local meta = minetest.get_meta(pos)
	local id = meta:get_int("smoke")
	if id ~= 0 then
		minetest.delete_particlespawner(id)
	end
	meta:set_int("smoke", nil)
end


local function collapse_pile(pos)
	local pos1 = {x=pos.x-1, y=pos.y, z=pos.z-1}
	local pos2 = {x=pos.x+1, y=pos.y+2, z=pos.z+1}
	ironage.swap_nodes(pos1, pos2, "group:wood", "ironage:charcoalblock_burn")
	stop_smoke(pos)
	make_dirt_with_ash(pos)
end

local function convert_to_coal(pos)
	local pos1 = {x=pos.x-1, y=pos.y+1, z=pos.z-1}
	local pos2 = {x=pos.x+1, y=pos.y+2, z=pos.z+1}
	ironage.swap_nodes(pos1, pos2, "group:wood", "air")
	pos1 = {x=pos.x-1, y=pos.y+0, z=pos.z-1}
	pos2 = {x=pos.x+1, y=pos.y+1, z=pos.z+1}
	ironage.swap_nodes(pos1, pos2, "group:wood", "ironage:charcoalblock")
	stop_smoke(pos)
	ironage.swap_node(pos, "ironage:charcoalblock")
	make_dirt_with_ash(pos)
	make_dirt_with_dry_grass(pos)
end	

function ironage.start_pile(pos)
	local meta = minetest.get_meta(pos)
	meta:set_int("ignite", minetest.get_gametime())
	minetest.get_node_timer(pos):start(5)
end


function ironage.keep_running_pile(pos)
	local meta = minetest.get_meta(pos)
	print("running", meta:get_int("running"), "ignite", meta:get_int("ignite"), "gametime", minetest.get_gametime())
	if meta:get_int("running") == 0 then
		if num_wood(pos) == 26 and num_dirt(pos) == 98 then
			minetest.get_node_timer(pos):stop()
			minetest.get_node_timer(pos):start(22)
			meta:set_int("running", 1)
			start_smoke(pos)
		elseif minetest.get_gametime() > (meta:get_int("ignite") + 10) then
			collapse_pile(pos)
			minetest.remove_node(pos)
			return false
		end
	else
		if num_wood(pos) ~= 26 or num_dirt(pos) ~= 98 then
			collapse_pile(pos)
			minetest.remove_node(pos)
			return false
		elseif minetest.get_gametime() > (meta:get_int("ignite") + PILE_BURN_TIME) then
			convert_to_coal(pos)
			return false
		end
	end
	return true
end

function ironage.stop_pile(pos)
	collapse_pile(pos)
end


minetest.register_node("ironage:dirt_with_ash", {
	description = "Dirt with Ash",
	tiles = {"ironage_ash.png",
		"default_dirt.png",
		{name = "default_dirt.png^ironage_ash_side.png",
			tileable_vertical = false}},
	groups = {crumbly = 3, soil = 1, spreading_dirt_type = 1},
	drop = 'default:dirt',
	sounds = default.node_sound_dirt_defaults({
		footstep = {name = "default_grass_footstep", gain = 0.4},
	}),
})


minetest.register_node("ironage:charcoalblock_burn", {
	tiles = {"ironage_charcoal_burn.png"},
	after_place_node = function(pos)
		minetest.get_node_timer(pos):start(math.random(60, 120))
	end,
	on_timer = function(pos)
		minetest.remove_node(pos)
		make_dirt_with_ash(pos)
		return false
	end,
	--drop = "",
	light_source = 10,
	is_ground_content = false,
	groups = {cracky = 3, falling_node = 1},
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("ironage:charcoalblock", {
	description = "Charcoal Block",
	tiles = {"ironage_charcoal.png"},
	on_ignite = function(pos, igniter)
		minetest.after(2, ironage.swap_node, pos, "ironage:charcoalblock_burn")
	end,
	is_ground_content = false,
	groups = {cracky = 3, falling_node = 1},  -- flammable=2, 
	sounds = default.node_sound_wood_defaults(),
})


minetest.register_craft({
	type = "fuel",
	recipe = "ironage:charcoalblock",
	burntime = 370,
})

minetest.register_lbm({
	label = "[ironage] Lighter update",
	name = "ironage:update",
	nodenames = {"ironage:lighter_burn"},
	run_at_every_load = true,
	action = function(pos, node)
		local meta = minetest.get_meta(pos)
		if meta:get_int("running") == 1 then
			start_smoke(pos)
		end
	end
})
