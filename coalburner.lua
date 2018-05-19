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

local function num_coal(pos)
	local pos1 = {x=pos.x, y=pos.y+1, z=pos.z}
	local pos2 = {x=pos.x, y=pos.y+32, z=pos.z}
	local nodes = minetest.find_nodes_in_area(pos1, pos2, {"ironage:charcoal", "ironage:charcoal_burn"})
	return #nodes
end

local function num_cobble(pos, height)
	local pos1 = {x=pos.x-1, y=pos.y+1, z=pos.z-1}
	local pos2 = {x=pos.x+1, y=pos.y+height, z=pos.z+1}
	local nodes = minetest.find_nodes_in_area(pos1, pos2, {"default:cobble", "default:desert_cobble"})
	return #nodes
end

local function start_burner(pos, height)
	local pos1 = {x=pos.x-1, y=pos.y+1, z=pos.z-1}
	local pos2 = {x=pos.x+1, y=pos.y+height, z=pos.z+1}
	ironage.swap_nodes(pos1, pos2, "ironage:charcoal", "ironage:charcoal_burn")
end

local function remove_flame(pos, height)
	local idx
	pos = {x=pos.x, y=pos.y+height, z=pos.z}
	for idx=height,1,-1 do
		pos = {x=pos.x, y=pos.y+1, z=pos.z}
		local node = minetest.get_node(pos)
		if string.find(node.name, "ironage:flame") then
			minetest.remove_node(pos)
		end
	end
end

local function flame(pos, height, heat)
	local idx
	pos = {x=pos.x, y=pos.y+height, z=pos.z}
	for idx=heat,1,-1 do
		pos = {x=pos.x, y=pos.y+1, z=pos.z}
		idx = math.min(idx, 7)
		local node = minetest.get_node(pos)
		if node.name == "ironage:meltingpot_active" then
			return
		end
		if node.name == "ironage:meltingpot" then
			ironage.switch_to_active(pos)
			return
		end
		minetest.add_node(pos, {name = "ironage:flame"..idx})
		local meta = minetest.get_meta(pos)
		meta:set_int("heat", idx)
	end
end


lRatio = {120, 110, 95, 75, 55, 28, 0}
lColor = {"000080", "400040", "800000", "800000", "800000", "800000", "800000"}
for idx,ratio in ipairs(lRatio) do
	local color = "ironage_flame_animated.png^[colorize:#"..lColor[idx].."B0:"..ratio
	minetest.register_node("ironage:flame"..idx, {
		tiles = {
			{
				name = color,
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 1
				},
			},
		},
		
		after_destruct = function(pos, oldnode)
			pos.y = pos.y + 1
			local node = minetest.get_node(pos)
			if minetest.get_item_group(node.name, "ironage_flame") > 0 then
				minetest.remove_node(pos)
			end
		end,
		
		use_texture_alpha = true,
		inventory_image = "ironage_flame.png",
		paramtype = "light",
		light_source = 13,
		walkable = false,
		buildable_to = true,
		floodable = true,
		sunlight_propagates = true,
		damage_per_second = 4 + idx,
		groups = {igniter = 2, dig_immediate = 3, ironage_flame=1},
		drop = "",
	})
end

minetest.register_node("ironage:ash", {
	description = S("Ash"),
	tiles = {"ironage_ash.png"},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-4/8, -4/8, -4/8,  4/8, -3/8, 4/8},
		},
	},
	is_ground_content = false,
	groups = {cracky = 3},
	drop = "",
	sounds = default.node_sound_defaults(),
})

function ironage.start_burner(pos)
	local height = num_coal(pos)
	if num_cobble(pos, height) == height * 8 then
		local meta = minetest.get_meta(pos)
		meta:set_int("ignite", minetest.get_gametime())
		meta:set_int("height", height)
		start_burner(pos, height)
		flame(pos, height, height)
		local handle = minetest.sound_play("ironage", {
				pos = {x=pos.x, y=pos.y+height, z=pos.z}, 
				max_hear_distance = 20, 
				gain = height/32.0, 
				loop = true})
		meta:set_int("handle", handle)
		minetest.get_node_timer(pos):start(5)
	end
end

function ironage.keep_running_burner(pos)
	local meta = minetest.get_meta(pos)
	local height = meta:get_int("height")
	remove_flame(pos, height)
	local handle = meta:get_int("handle")
	if handle then
		minetest.sound_stop(handle)
		meta:set_int("handle", nil)
	end
	local new_height = num_coal(pos)
	if new_height > 0 then
		flame(pos, height, new_height)
		handle = minetest.sound_play("ironage", {
				pos = {x=pos.x, y=pos.y+height, z=pos.z}, 
				max_hear_distance = 32, 
				gain = new_height/32.0, 
				loop = true})
		meta:set_int("handle", handle)
	else
		minetest.swap_node(pos, {name="ironage:ash"})
		return false
	end
	return true
end

function ironage.stop_burner(pos)
	local meta = minetest.get_meta(pos)
	local height = meta:get_int("height")
	remove_flame(pos, height)
	local handle = meta:get_int("handle")
	minetest.sound_stop(handle)
end
