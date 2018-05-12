--[[

	Iron Age
	========

	Copyright (C) 2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

]]--


--
-- Items
--
local NODE_POINTS = 10

local function swap_node(pos, name)
	minetest.remove_node(pos)
	minetest.place_node(pos, {name = name})
end



local function flame(pos, heat_points)
	local idx
	heat_points = math.min(heat_points, 300) / 20
	heat_points = math.floor(heat_points)
	print("heat_points", heat_points)
	for idx=heat_points,1,-1 do
		pos = {x=pos.x, y=pos.y+1, z=pos.z}
		idx = math.min(idx, 7)
		local node = minetest.get_node(pos)
		if node.name == "ironage:meltingpot" then
			return
		end
		minetest.add_node(pos, {name = "ironage:permanent_flame"..idx})
		local meta = minetest.get_meta(pos)
		meta:set_int("heat", heat_points)
		meta:set_string("infotext", heat_points)
	end
end


local function add_heat_points(pos, points)
	local meta = minetest.get_meta(pos)
	points = meta:get_int("heat_points") + points
	meta:set_int("heat_points", points)
end	

local function calc_heat_points(pos)
	-- determine own node temperature points
	local meta = minetest.get_meta(pos)
	local points = meta:get_int("heat_points") + NODE_POINTS
	meta:set_int("heat_points", 0)
	
	-- remove burnable nodes
	local p = minetest.find_node_near(pos, 1, {"group:flammable"})
	if p then
		minetest.remove_node(p)	
	end
	
	-- some losses through air around
	local pos1 = {x=pos.x-1, y=pos.y, z=pos.z-1}
	local pos2 = {x=pos.x+1, y=pos.y, z=pos.z+1}
	for _,_ in ipairs(minetest.find_nodes_in_area(pos1, pos2, "air")) do
		points = points * 0.9
	end
	
	-- store
	meta:set_string("infotext", points)
	
	-- pass on points to upper nodes
	pos1 = {x=pos.x, y=pos.y+1, z=pos.z}
	local node = minetest.get_node(pos1)
	if node.name == "air" or minetest.get_item_group(node.name, "myflame") > 0 then
		return points
	elseif minetest.get_node(pos1).name == "ironage:charcoalblock_burn" then
		add_heat_points(pos1, points)
	else
		pos1 = {x=pos.x-1, y=pos.y+1, z=pos.z-1}
		pos2 = {x=pos.x+1, y=pos.y+1, z=pos.z+1}
		for _,npos in ipairs(minetest.find_nodes_in_area(pos1, pos2, "ironage:charcoalblock_burn")) do
			add_heat_points(npos, points)
			break
		end
	end
	return 0
end

minetest.register_node("ironage:basic_flame", {
	drawtype = "firelike",
	tiles = {
		{
			name = "ironage_basic_flame_animated.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 1
			},
		},
	},
	inventory_image = "ironage_basic_flame.png",
	paramtype = "light",
	light_source = 13,
	walkable = false,
	buildable_to = true,
	sunlight_propagates = true,
	damage_per_second = 4,
	groups = {igniter = 2, dig_immediate = 3, not_in_creative_inventory = 1},
	on_timer = function(pos)
		local f = minetest.find_node_near(pos, 1, {"ironage:charcoalblock_burn"})
		if not f then
			minetest.remove_node(pos)
			return
		end
		-- Restart timer
		return true
	end,
	drop = "",

	on_construct = function(pos)
		minetest.get_node_timer(pos):start(math.random(30, 60))
	end,
})

lRatio = {120, 110, 95, 75, 55, 28, 0}
lColor = {"000080", "400040", "800000", "800000", "800000", "800000", "800000"}
for idx,ratio in ipairs(lRatio) do
	local color = "ironage_basic_flame_animated1.png^[colorize:#"..lColor[idx].."B0:"..ratio
	minetest.register_node("ironage:permanent_flame"..idx, {
		description = "My Permanent Flame "..idx,
		--drawtype = "firelike",
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
			if minetest.get_item_group(node.name, "myflame") > 0 then
				minetest.remove_node(pos)
			end
		end,
		
		use_texture_alpha = true,
		inventory_image = "ironage_basic_flame.png",
		paramtype = "light",
		param2 = idx,
		light_source = 13,
		walkable = false,
		buildable_to = true,
		floodable = true,
		sunlight_propagates = true,
		damage_per_second = 4 + idx,
		groups = {igniter = 2, dig_immediate = 3, myflame=1},
		drop = "",
	})
end

minetest.register_node("ironage:meltingpot", {
	description = "Melting Pot",
	tiles = {
		{
			image = "ironage_meltingpot_top.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 1,
			},
		},
		"ironage_meltingpot.png",
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-10/16, -8/16, -10/16,  10/16, 8/16,  -6/16},
			{-10/16, -8/16,   6/16,  10/16, 8/16,  10/16},
			{-10/16, -8/16, -10/16,  -6/16, 8/16,  10/16},
			{  6/16, -8/16, -10/16,  10/16, 8/16,  10/16},
			{ -6/16, -8/16,  -6/16,   6/16, 4/16,   6/16},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {-10/16, -8/16, -10/16,  10/16, 8/16,  10/16},
	},
	is_ground_content = false,
	groups = {cracky = 3},
	sounds = default.node_sound_metal_defaults(),
})

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


local function ignite_next_coal_block(pos)
	local p = minetest.find_node_near(pos, 1, {"ironage:charcoalblock"})
	if p then
		swap_node(p, "ironage:charcoalblock_burn")
	end
	local p = minetest.find_node_near(pos, 1, {"ironage:charcoalblock"})
	if p then
		swap_node(p, "ironage:charcoalblock_burn")
	end
end

minetest.register_node("ironage:charcoalblock_burn", {
	tiles = {"ironage_charcoal_burn.png"},
	on_construct = function(pos)
		--minetest.get_node_timer(pos):start(math.random(30, 60))
		minetest.get_node_timer(pos):start(1)
		--print("on_construct")
	end,
	after_place_node = function(pos)
		--print("after_place_node")
		pos.y = pos.y + 1
		if minetest.get_node(pos).name == "ironage:basic_flame" then
			minetest.remove_node(pos)
		end	
	end,
	on_timer = function(pos)
		local meta = minetest.get_meta(pos)
		local points = calc_heat_points(pos)
		flame(pos, points)
		ignite_next_coal_block(pos)
		return true
	end,
	after_destruct = function(pos, oldnode)
		local meta = minetest.get_meta(pos)
		pos.y = pos.y - 1
		if minetest.get_node(pos).name == "group:dirt" then
			minetest.swap_node(pos, {name = "ironage:dirt_with_ash"})
		end
	end,
	--drop = "",
	light_source = 10,
	is_ground_content = false,
	groups = {cracky = 3, falling_node = 1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("ironage:charcoalblock", {
	description = "Charcoal Block",
	tiles = {"ironage_charcoal.png"},
	on_ignite = function(pos, igniter)
		local flame_pos = {x = pos.x, y = pos.y + 1, z = pos.z}
		if minetest.get_node(flame_pos).name == "air" then
			minetest.set_node(flame_pos, {name = "ironage:basic_flame"})
			minetest.after(5, swap_node, pos, "ironage:charcoalblock_burn")
		end
	end,
	is_ground_content = false,
	groups = {cracky = 3, falling_node = 1},  -- flammable=2, 
	sounds = default.node_sound_stone_defaults(),
})


minetest.register_craft({
	type = "fuel",
	recipe = "ironage:charcoalblock",
	burntime = 370,
})

