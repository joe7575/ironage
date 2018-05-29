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

local SMELTING_TIME = 2

local Tabs = S("Menu,Recipes,Pile,Burner")

local PileHelp = S([[Coal Pile to produce charcoal:
- build a 5x5 block dirt base
- place a lighter in the centre
- build a 3x3x3 wood cube around
- cover all with dirt to a 5x5x5 cube
- keep a hole to the lighter
- ignite the lighter and immediately
- close the pile with one wood and one dirt
- open the pile after the smoke disappeared]])

local BurnerHelp = S([[Coal Burner to heat the melting pot:
- build a 3x3xN cobble tower
- more height means more flame heat   
- keep a hole open on one side
- put a lighter in
- fill the tower from the top with charcoal
- ignite the lighter
- place the pot in the flame]])

local PileImages = {
	"default_dirt", "default_dirt", "default_dirt",    "default_dirt", "default_dirt",
	"default_dirt", "default_wood", "default_wood",    "default_wood", "default_dirt",
	"default_dirt", "default_wood", "default_wood",    "default_wood", "default_dirt",
	"default_dirt", "default_wood", "ironage_lighter", "default_wood", "default_dirt",
	"default_dirt", "default_dirt", "default_dirt",    "default_dirt", "default_dirt",
}

local BurnerImages = {
	false, false, "default_cobble", "ironage_charcoal", "default_cobble",
	false, false, "default_cobble", "ironage_charcoal", "default_cobble",
	false, false, "default_cobble", "ironage_charcoal", "default_cobble",
	false, false, false,            "ironage_lighter",  "default_cobble",
	false, false, "default_cobble", "default_cobble",   "default_cobble",
}

local Recipes = {}     -- registered recipes
local KeyList = {}     -- index to Recipes key translation
local NumRecipes = 0
local Cache = {}       -- store melting pot inventory data

-- formspec images
local function draw(images)
	local tbl = {}
	for y=0,4 do
		for x=0,4 do
			local idx = 1 + x + y * 5
			local img = images[idx]
			if img ~= false then
				tbl[#tbl+1] = "image["..(x*0.8)..","..(y*0.8)..";0.8,0.8;"..img..".png]"
			end
		end
	end
	return table.concat(tbl)
end	

local formspec1 = 
	"size[8,8]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"tabheader[0,0;tab;"..Tabs..";1;;true]"..
	"label[1,0.2;"..S("Menu").."]"..
	
	"container[1,1]"..
	"list[current_name;src;0,0;2,2;]"..
	"item_image[2.6,0;0.8,0.8;ironage:meltingpot]"..
	"image[2.3,0.6;1.6,1;gui_furnace_arrow_bg.png^[transformR270]"..
	"list[current_name;dst;4,0;2,2;]"..
	"container_end[]"..
	
	"list[current_player;main;0,4;8,4;]"..
	"listring[current_name;dst]"..
	"listring[current_player;main]"..
	"listring[current_name;src]"..
	"listring[current_player;main]"

local function formspec2(idx)
	local key = KeyList[idx]
	local input1 = Recipes[key].input[1] or ""
	local input2 = Recipes[key].input[2] or ""
	local input3 = Recipes[key].input[3] or ""
	local input4 = Recipes[key].input[4] or ""
	local num = Recipes[key].number
	local heat = Recipes[key].heat
	local time = Recipes[key].time
	local output = Recipes[key].output
	if num > 1 then
		output = output.." "..num
	end
	return "size[8,8]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"tabheader[0,0;tab;"..Tabs..";2;;true]"..
	"label[1,0.2;"..S("Melting Guide").."]"..
	
	"container[1,1]"..
	"item_image_button[0,0;1,1;"..input1..";b1;]"..
	"item_image_button[1,0;1,1;"..input2..";b2;]"..
	"item_image_button[0,1;1,1;"..input3..";b3;]"..
	"item_image_button[1,1;1,1;"..input4..";b4;]"..
	"item_image[2.6,0;0.8,0.8;ironage:meltingpot]"..
	"image[2.3,0.6;1.6,1;gui_furnace_arrow_bg.png^[transformR270]"..
	"item_image_button[4,0.5;1,1;"..output..";b5;]"..
	"label[2,2.2;"..S("Heat")..": "..heat.."  /  "..S("Time")..": "..time.." s]"..
	"label[2,4;Recipe "..idx.." of "..NumRecipes.."]"..
	"button[2,5.5;1,1;priv;<<]"..
	"button[3,5.5;1,1;next;>>]"..
	"container_end[]"
end


local formspec3 = 
	"size[8,8]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"tabheader[0,0;tab;"..Tabs..";3;;true]"..
	"label[0,0;"..PileHelp.."]"..
	"label[1,5;"..S("Cross-section")..":]"..
	"container[4,4]"..
	draw(PileImages)..
	"container_end[]"

local formspec4 = 
	"size[8,8]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"tabheader[0,0;tab;"..Tabs..";4;;true]"..
	"label[0,0;"..BurnerHelp.."]"..
	"label[1,5;"..S("Cross-section")..":]"..
	"container[4,4]"..
	draw(BurnerImages)..
	"container_end[]"

local function on_receive_fields(pos, formname, fields, sender)
	local meta = minetest.get_meta(pos)
	local recipe_idx = meta:get_int("recipe_idx")
	if recipe_idx == 0 then recipe_idx = 1 end
	if fields.tab == "1" then
		meta:set_string("formspec", formspec1)
	elseif fields.tab == "2" then
		meta:set_string("formspec", formspec2(recipe_idx))
	elseif fields.tab == "3" then
		meta:set_string("formspec", formspec3)
	elseif fields.tab == "4" then
		meta:set_string("formspec", formspec4)
	elseif fields.next == ">>" then
		recipe_idx = math.min(recipe_idx + 1, NumRecipes)
		meta:set_int("recipe_idx", recipe_idx)
		meta:set_string("formspec", formspec2(recipe_idx))
	elseif fields.priv == "<<" then
		recipe_idx = math.max(recipe_idx - 1, 1)
		meta:set_int("recipe_idx", recipe_idx)
		meta:set_string("formspec", formspec2(recipe_idx))
	end
end

local function can_dig(pos, player)
	local meta = minetest.get_meta(pos);
	local inv = meta:get_inventory()
	return inv:is_empty("dst") and inv:is_empty("src")
end

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	if listname == "src" then
		return stack:get_count()
	elseif listname == "dst" then
		return 0
	end
end

local function allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local stack = inv:get_stack(from_list, from_index)
	return allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	return stack:get_count()
end

-- determine recipe based on inventory items
local function get_recipe(inv)
	-- collect items
	local stacks = {}
	local names = {}
	local numbers = {}
	for _,stack in ipairs(inv:get_list("src")) do
		if not stack:is_empty() then
			table.insert(names, stack:get_name())
			table.insert(numbers, 1)
			table.insert(stacks, stack)
		else
			table.insert(numbers, 0)
			table.insert(stacks, ItemStack(""))
		end
	end
	-- determine output
	table.sort(names)
	local key = table.concat(names, "-")
	local output = Recipes[key]
	
	if output then
		return {
			numbers = numbers,
			stacks = stacks,
			output = ItemStack(output.output.." "..output.number),
			heat = output.heat,
			time = output.time,
		}
	end
	return nil
end

-- prepare recipe and store in cache table for faster access
local function store_recipe_in_cache(pos)
	local hash = minetest.hash_node_position(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local recipe = get_recipe(inv)
	Cache[hash] = recipe
	return recipe
end

-- read value from the node below
local function get_heat(pos)
	local heat = 0
	pos.y = pos.y - 1
	local node = minetest.get_node(pos)
	local meta = minetest.get_meta(pos)
	pos.y = pos.y + 1
	if minetest.get_item_group(node.name, "ironage_flame") > 0 then
		heat = meta:get_int("heat")
	end
	return heat
end
	
-- Start melting if heat is ok AND source items available
function ironage.switch_to_active(pos)
	local meta = minetest.get_meta(pos)
	local heat = get_heat(pos)
	local recipe = store_recipe_in_cache(pos)
	
	if recipe and heat >= recipe.heat then
		minetest.swap_node(pos, {name = "ironage:meltingpot_active"})
		minetest.registered_nodes["ironage:meltingpot_active"].on_construct(pos)
		meta:set_string("infotext", S("Melting Pot active (heat=")..heat..")")
		minetest.get_node_timer(pos):start(2)
		return true
	end
	meta:set_string("infotext", S("Melting Pot inactive (heat=")..heat..")")
	return false
end	

local function set_inactive(meta, pos, heat)
	minetest.get_node_timer(pos):stop()
	minetest.swap_node(pos, {name = "ironage:meltingpot"})
	minetest.registered_nodes["ironage:meltingpot"].on_construct(pos)
	meta:set_string("infotext", S("Melting Pot inactive (heat=")..heat..")")
end

-- Stop melting if heat to low OR no source items available
local function switch_to_inactive(pos)
	local meta = minetest.get_meta(pos)
	local heat = get_heat(pos)
	local hash = minetest.hash_node_position(pos)
	local recipe = Cache[hash] or store_recipe_in_cache(pos)
	
	if not recipe or heat < recipe.heat then
		set_inactive(meta, pos, heat)
		return true
	end
	meta:set_string("infotext", S("Melting Pot active (heat=")..heat..")")
	return false
end	

-- move recipe src items to output inventory
local function process(inv, recipe, heat)
	if heat < recipe.heat then
		return false
	end
	for idx,num in ipairs(recipe.numbers) do
		local stack = recipe.stacks[idx]
	end
	if inv:room_for_item("dst", recipe.output) then
		for idx,num in ipairs(recipe.numbers) do
			local stack = recipe.stacks[idx]
			if num == 1 then
				if stack and stack:get_count() > 0 then
					stack:take_item(1)
				else
					return false
				end
			end
		end
		inv:add_item("dst", recipe.output)
		inv:set_list("src", recipe.stacks)
		return true
	end
	return false
end		

local function smelting(pos, recipe, heat, elapsed)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	elapsed = elapsed + meta:get_int("leftover")
	
	while elapsed >= recipe.time do
		if process(inv, recipe, heat) == false then 
			meta:set_int("leftover", 0)
			set_inactive(meta, pos, heat)
			return false
		end
		elapsed = elapsed - recipe.time
	end
	meta:set_int("leftover", elapsed)
	return true
end

local function pot_node_timer(pos, elapsed)
	if switch_to_inactive(pos) == false then
		local hash = minetest.hash_node_position(pos)
		local heat = get_heat(pos)
		local recipe = Cache[hash] or store_recipe_in_cache(pos)
		if recipe then
			return smelting(pos, recipe, heat, elapsed)
		end
	end
	return false
end

minetest.register_node("ironage:meltingpot_active", {
	description = S("Melting Pot"),
	tiles = {
		{
			image = "ironage_meltingpot_top_active.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 1,
			},
		},
		"default_cobble.png^ironage_meltingpot.png",
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-10/16, -8/16, -10/16,  10/16, 9/16,  -6/16},
			{-10/16, -8/16,   6/16,  10/16, 9/16,  10/16},
			{-10/16, -8/16, -10/16,  -6/16, 9/16,  10/16},
			{  6/16, -8/16, -10/16,  10/16, 9/16,  10/16},
			{ -6/16, -8/16,  -6/16,   6/16, 5/16,   6/16},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {-10/16, -8/16, -10/16,  10/16, 9/16,  10/16},
	},
	
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", formspec1)
		local inv = meta:get_inventory()
		inv:set_size('src', 4)
		inv:set_size('dst', 4)
	end,
	
	on_timer = function(pos, elapsed)
		return pot_node_timer(pos, elapsed)
	end,
	
	on_receive_fields = function(pos, formname, fields, sender)
		on_receive_fields(pos, formname, fields, sender)
	end,
	
	on_metadata_inventory_move = function(pos)
		store_recipe_in_cache(pos)
		switch_to_inactive(pos)
	end,
	
	on_metadata_inventory_put = function(pos)
		store_recipe_in_cache(pos)
		switch_to_inactive(pos)
	end,
	
	on_metadata_inventory_take = function(pos)
		store_recipe_in_cache(pos)
		switch_to_inactive(pos)
	end,
	
	can_dig = can_dig,
	
	drop = "ironage:meltingpot",
	is_ground_content = false,
	groups = {cracky = 3, not_in_creative_inventory=1},
	sounds = default.node_sound_metal_defaults(),

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
})

minetest.register_node("ironage:meltingpot", {
	description = S("Melting Pot"),
	tiles = {
		"default_cobble.png",
		"default_cobble.png^ironage_meltingpot.png",
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-10/16, -8/16, -10/16, 10/16,  9/16, -6/16},
			{-10/16, -8/16,   6/16, 10/16,  9/16, 10/16},
			{-10/16, -8/16, -10/16, -6/16,  9/16, 10/16},
			{  6/16, -8/16, -10/16, 10/16,  9/16, 10/16},
			{ -6/16, -8/16,  -6/16,  6/16, -4/16,  6/16},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {-10/16, -8/16, -10/16, 10/16, 9/16, 10/16},
	},
	
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", formspec1)
		meta:set_string("infotext", S("Melting Pot inactive (heat=0)"))
		local inv = meta:get_inventory()
		inv:set_size('src', 4)
		inv:set_size('dst', 4)
	end,
	
	on_metadata_inventory_move = function(pos)
		store_recipe_in_cache(pos)
		ironage.switch_to_active(pos)
	end,
	
	on_metadata_inventory_put = function(pos)
		store_recipe_in_cache(pos)
		ironage.switch_to_active(pos)
	end,
	
	on_metadata_inventory_take = function(pos)
		store_recipe_in_cache(pos)
		ironage.switch_to_active(pos)
	end,
	
	on_receive_fields = function(pos, formname, fields, sender)
		on_receive_fields(pos, formname, fields, sender)
	end,
	
	can_dig = can_dig,
	
	is_ground_content = false,
	groups = {cracky = 3},
	sounds = default.node_sound_metal_defaults(),

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
})

minetest.register_craft({
	output = "ironage:meltingpot",
	recipe = {
		{"default:cobble", "default:bronze_ingot", "default:cobble"},
		{"default:cobble", "",                     "default:cobble"},
		{"default:cobble", "default:cobble",       "default:cobble"},
	},
})

if minetest.global_exists("unified_inventory") then
	unified_inventory.register_craft_type("melting", {
		description = S("Melting"),
		icon = "default_cobble.png^ironage_meltingpot.png",
		width = 2,
		height = 2,
	})
	unified_inventory.register_craft_type("burning", {
		description = S("Burning"),
		icon = "ironage_smoke.png",
		width = 1,
		height = 1,
	})
	unified_inventory.register_craft({
		output = "ironage:charcoal",
		items = {"group:wood"},
		type = "burning",
	})
end

function ironage.register_recipe(recipe)
	--table.sort(recipe.recipe)
	local names = table.copy(recipe.recipe)
	table.sort(names)
	local key = table.concat(names, "-")
	local output = string.split(recipe.output, " ")
	local number = tonumber(output[2] or 1)
	table.insert(KeyList, key)
	Recipes[key] = {
		input = recipe.recipe,
		output = output[1],
		number = number,
		heat = math.max(recipe.heat or 3, 2),
		time = math.max(recipe.time or 2, 2*number),
	}
	NumRecipes = NumRecipes + 1

	if minetest.global_exists("unified_inventory") then
		recipe.items = recipe.recipe
		recipe.type = "melting"
		unified_inventory.register_craft(recipe)
	end
end

