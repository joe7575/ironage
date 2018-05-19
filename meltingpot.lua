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

local PileHelp = S([[Coal Pile Instructions:
- build a 5x5 block dirt base
- place a lighter in the centre
- build a 3x3x3 wood cube around
- cover all with dirt to a 5x5x5 cube
- keep a hole to the lighter
- ignite the lighter
- close the pile with one wood and one dirt
- wait until the smoke disappears
- now you can open the pile]])

local BurnerHelp = S([[Coal Burner Instructions:
- build a cobble tower 
    (3x3 blocks base with variable height)
- keep a hole open on one side
- put a lighter in
- fill the tower from the top with charcoal
- ignite the lighter
- place the pot into the flame]])

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

local Recipes = {}
local KeyList = {}
local NumRecipes = 0
local Cache = {}

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
	if not key then print("idx", idx); return "" end
	local input1 = Recipes[key].input[1] or ""
	local input2 = Recipes[key].input[2] or ""
	local input3 = Recipes[key].input[3] or ""
	local input4 = Recipes[key].input[4] or ""
	local num = Recipes[key].number
	local output1 = Recipes[key].output
	local output2 = ""
	local output3 = ""
	local output4 = ""
	if num == 2 then
		output2 = output1
	elseif num == 3 then
		output2 = output1
		output3 = output1
	elseif num == 4 then
		output2 = output1
		output3 = output1
		output4 = output1
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
	"item_image_button[4,0;1,1;"..output1..";b5;]"..
	"item_image_button[5,0;1,1;"..output2..";b6;]"..
	"item_image_button[4,1;1,1;"..output3..";b7;]"..
	"item_image_button[5,1;1,1;"..output4..";b8;]"..
	"label[2,2.5;Recipe "..idx.." of "..NumRecipes.."]"..
	"button[2,3;1,1;priv;<<]"..
	"button[3,3;1,1;next;>>]"..
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
	--print("fields", dump(fields))
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

local function get_output(input)
	table.sort(input)
	local key = table.concat(input, "-")
	return Recipes[key]
end

local function get_recipe(inv)
	-- collect items
	local items = {}
	local input = {}
	for _,stack in ipairs(inv:get_list("src")) do
		if not stack:is_empty() then
			table.insert(input, stack:get_name())
			table.insert(items, ItemStack(stack:get_name()))
		end
	end
	-- determine output
	local output = get_output(input)
	if output then
		return {
			items = items,
			output = ItemStack(output.output.." "..output.number),
			heat = output.heat,
			time = output.time,
		}
	end
	return nil
end

-- prepare recipe and store in table for faster access
local function store_recipe_in_cache(pos)
	local hash = minetest.hash_node_position(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local recipe = get_recipe(inv)
	if recipe then
		Cache[hash] = recipe
		return recipe
	end
	return false
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
	
-- Start melting if heat>0 AND source items available
function ironage.switch_to_active(pos)
	local meta = minetest.get_meta(pos)
	local heat = get_heat(pos)
	local inv = meta:get_inventory()
	
	if heat > 0 and not inv:is_empty("src") then
		if store_recipe_in_cache(pos) then
			minetest.swap_node(pos, {name = "ironage:meltingpot_active"})
			minetest.registered_nodes["ironage:meltingpot_active"].on_construct(pos)
			meta:set_string("infotext", S("Melting Pot active (heat=")..heat..")")
			minetest.get_node_timer(pos):start(2)
			return true
		end
	end
	return false
end	

-- Stop melting if heat==0 OR no source items available
local function switch_to_inactive(pos)
	local meta = minetest.get_meta(pos)
	local heat = get_heat(pos)
	local inv = meta:get_inventory()
	
	if heat == 0 or inv:is_empty("src") then
		minetest.get_node_timer(pos):stop()
		minetest.swap_node(pos, {name = "ironage:meltingpot"})
		minetest.registered_nodes["ironage:meltingpot"].on_construct(pos)
		meta:set_string("infotext", S("Melting Pot inactive"))
		return true
	end
	return false
end	


-- check if inventory has all needed items
local function contains_items(inv, listname, items)
	for _,item in ipairs(items) do
		if not inv:contains_item(listname, item) then
			return false
		end
	end
	return true
end

-- move recipe src items to dst output
local function process(inv, recipe)
	if contains_items(inv, "src", recipe.items) then
		if inv:room_for_item("dst", recipe.output) then
			for _,item in ipairs(recipe.items) do
				inv:remove_item("src", item)
			end
			inv:add_item("dst", recipe.output)
			return true
		end	
	end
	return false
end		

local function smelting(pos, recipe, heat, elapsed)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	elapsed = elapsed + meta:get_int("leftover")
	
	while heat >= recipe.heat and elapsed >= recipe.time do
		print("process", elapsed)
		if process(inv, recipe) == false then 
			meta:set_int("leftover", 0)
			return 
		end
		elapsed = elapsed - recipe.time
	end
	meta:set_int("leftover", elapsed)
	return true
end

local function pot_node_timer(pos, elapsed)
	print("pot_node_timer", elapsed)
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
	
	can_dig = can_dig,
	
	drop = "ironage:meltingpot",
	is_ground_content = false,
	groups = {cracky = 3},
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
		meta:set_string("infotext", S("Melting Pot inactive"))
		local inv = meta:get_inventory()
		inv:set_size('src', 4)
		inv:set_size('dst', 4)
	end,
	
	on_metadata_inventory_move = function(pos)
		if store_recipe_in_cache(pos) then
			ironage.switch_to_active(pos)
		end
	end,
	
	on_metadata_inventory_put = function(pos)
		if store_recipe_in_cache(pos) then
			ironage.switch_to_active(pos)
		end
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

unified_inventory.register_craft_type("melting", {
	description = S("Melting"),
	icon = "default_cobble.png^ironage_meltingpot.png",
	width = 2,
	height = 2,
})

function ironage.register_recipe(recipe)
	table.sort(recipe.recipe)
	local key = table.concat(recipe.recipe, "-")
	local output = string.split(recipe.output, " ")
	table.insert(KeyList, key)
	Recipes[key] = {
		input = recipe.recipe,
		output = output[1],
		number = tonumber(output[2] or 1),
		heat = recipe.heat or 3,
		time = recipe.time or 2,
	}
	NumRecipes = NumRecipes + 1

	recipe.items = recipe.recipe
	recipe.type = "melting"
	unified_inventory.register_craft(recipe)
end

