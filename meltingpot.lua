--[[

	Iron Age
	========

	Copyright (C) 2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

]]--

local MELTING_TIME = 2

local function stacklist_dbg(lists)
	for _,item in ipairs(lists) do
		print(item:get_name(), item:get_count())
	end
end

local Recipes = {}
local KeyList = {}
local NumRecipes = 0

local BurnerImages = {
	"default_dirt", "default_dirt", "default_dirt",    "default_dirt", "default_dirt",
	"default_dirt", "default_wood", "default_wood",    "default_wood", "default_dirt",
	"default_dirt", "default_wood", "default_wood",    "default_wood", "default_dirt",
	"default_dirt", "default_wood", "ironage_lighter", "default_wood", "default_dirt",
	"default_dirt", "default_dirt", "default_dirt",    "default_dirt", "default_dirt",
}

local formspec1 = 
	"size[8,8.5]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"tabheader[0,0;tab;Inventory,Recipes,Burner,Pile;1;;true]"..
	"label[1,0.2;Inventory]"..
	
	"container[1,1]"..
	"list[current_name;src;0,0;2,2;]"..
	"item_image[2.1,0;0.8,0.8;ironage:meltingpot]"..
	"image[2,0.6;1,1;gui_furnace_arrow_bg.png^[transformR270]"..
	"list[current_name;dst;3,0;2,2;]"..
	"container_end[]"..
	
	"list[current_player;main;0,4.5;8,4;]"..
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
	return "size[8,8.5]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"tabheader[0,0;tab;Inventory,Recipes,Burner,Pile;2;;true]"..
	"label[1,0.2;Melting Guide]"..
	
	"container[1,1]"..
	"item_image_button[0,0;1,1;"..input1..";b1;]"..
	"item_image_button[1,0;1,1;"..input2..";b2;]"..
	"item_image_button[0,1;1,1;"..input3..";b3;]"..
	"item_image_button[1,1;1,1;"..input4..";b4;]"..
	"item_image[2.1,0;0.8,0.8;ironage:meltingpot]"..
	"image[2,0.6;1,1;gui_furnace_arrow_bg.png^[transformR270]"..
	"item_image_button[3,0;1,1;"..output1..";b5;]"..
	"item_image_button[4,0;1,1;"..output2..";b6;]"..
	"item_image_button[3,1;1,1;"..output3..";b7;]"..
	"item_image_button[4,1;1,1;"..output4..";b8;]"..
	"label[1,2.5;Recipe "..idx.." of "..NumRecipes.."]"..
	"button[1,3;1,1;priv;<<]"..
	"button[2,3;1,1;next;>>]"..
	"container_end[]"
end


local function blueprint(images)
	local tbl = {}
	for y=0,4 do
		for x=0,4 do
			local idx = 1 + x + y * 5
			local img = images[idx]
			tbl[#tbl+1] = "image["..(x*0.8)..","..(y*0.8)..";0.8,0.8;"..img..".png]"
		end
	end
	return table.concat(tbl)
end	

local formspec3 =
	"size[8,8.5]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"tabheader[0,0;tab;Inventory,Recipes,Burner,Pile;3;;true]"..
	"label[1,0.2;Coal Burner Blueprint]"..
	
	--"label[0,0;Coal Burner: 3x3xn cobble tower, lighter on the bottom]"..
	--"label[0,0.6;Fill with coal, ignite the lighter, place the pot]"..
	"container[2,4]"..
	blueprint(BurnerImages)..
	"container_end[]"

local formspec4 =
	"size[8,8.5]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"tabheader[0,0;tab;Inventory,Recipes,Burner,Pile;4;;true]"..
	"label[1,0.2;Coal Pile Blueprint]"..
	
	"label[0,0;Coal Pile: 5x5x5 dirt, 3x3x3 wood, one lighter]"..
	"label[0,0.6;Ignite the lighter, close the pile, wait 2 days]"..
	"label[0.5,1.5;1)]"..
	"label[4.5,1.5;2)]"..
	"label[0.5,5.2;3)]"..
	"label[4.5,5.2;4)]"..
	"image[1,1.5;4,4;ironage_pile1.png]"..
	"image[5,1.5;4,4;ironage_pile2.png]"..
	"image[1,5.2;4,4;ironage_pile3.png]"..
	"image[5,5.2;4,4;ironage_pile4.png]"

--
-- Node callback functions that are the same for active and inactive furnace
--

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

local function swap_node(pos, name)
	local node = minetest.get_node(pos)
	if node.name == name then
		return
	end
	node.name = name
	minetest.swap_node(pos, node)
end

local function get_output(input)
	table.sort(input)
	local key = table.concat(input, "-")
	return Recipes[key]
end

local function get_melting_result(srclist)
	local result
	local input = {}
	local new_src = {}
	for idx,stack in ipairs(srclist) do
		if not stack:is_empty() then
			table.insert(input, stack:get_name())
			stack:take_item(1)
			new_src[idx] = stack
		else
			new_src[idx] = nil
		end
	end
	print("input", dump(input))
	local output = get_output(input)
	if output then
		result = {
			item = ItemStack(output.output.." "..output.number),
			heat = output.heat,
		}
	end
		
	return result, new_src
end

local function on_receive_fields(pos, formname, fields, sender)
	print("fields", dump(fields))
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

local function pot_node_timer(pos, elapsed)
	local meta = minetest.get_meta(pos)
	local src_time = meta:get_int("src_time")
	src_time = src_time + elapsed
	local heat = meta:get_int("heat")
	heat = 4
	local inv = meta:get_inventory()
	local srclist
	local result
	local new_src
	local update = true
	while update do
		update = false

		srclist = inv:get_list("src")

		-- Check if we have meltable content
		local new_src
		result, new_src = get_melting_result(srclist)
--		if result then
--			print("result")
--			stacklist_dbg({result.item})
--			stacklist_dbg(new_src)
--		end
		-- Check if we have enough heat
		if result and heat >= result.heat then
			-- If there is a meltable item then check if it is ready yet
			if src_time >= MELTING_TIME then
				-- Place result in dst list if possible
				if inv:room_for_item("dst", result.item) then
					inv:add_item("dst", result.item)
					inv:set_stack("src", 1, new_src[1])
					inv:set_stack("src", 2, new_src[2])
					inv:set_stack("src", 3, new_src[3])
					src_time = src_time - MELTING_TIME
					update = true
				end
			end
		end
	end
	
	if srclist[1]:is_empty() and srclist[2]:is_empty() and srclist[3]:is_empty() then
		src_time = 0
	end
	--
	-- Set meta values
	--
	meta:set_int("src_time", src_time)
	meta:set_string("infotext", "Melting Pot: heat="..heat)
	
--	if heat == 0 then
--		minetest.swap_node(pos, {name = "ironage:meltingpot"})
--		return false
--	end
	return true
end


minetest.register_node("ironage:meltingpot_active", {
	description = "Melting Pot",
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
		"ironage_meltingpot.png",
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
	
	after_place_node = function(pos)
		minetest.get_node_timer(pos):start(5)
	end,
	
	on_timer = function(pos, elapsed)
		return pot_node_timer(pos, elapsed)
	end,
	
	on_receive_fields = function(pos, formname, fields, sender)
		on_receive_fields(pos, formname, fields, sender)
	end,
	
	drop = "ironage:meltingpot",
	is_ground_content = false,
	groups = {cracky = 3},
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node("ironage:meltingpot", {
	description = "Melting Pot",
	tiles = {
		"ironage_meltingpot_top.png",
		"ironage_meltingpot.png",
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
		local inv = meta:get_inventory()
		inv:set_size('src', 4)
		inv:set_size('dst', 4)
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		on_receive_fields(pos, formname, fields, sender)
	end,
	is_ground_content = false,
	groups = {cracky = 3},
	sounds = default.node_sound_metal_defaults(),
})

function ironage.register_recipe(input, output, heat)
	if type(input) == "string" then
		input = {input}
	end
	table.sort(input)
	local key = table.concat(input, "-")
	output = string.split(output, " ")
	if not output[2] then output[2] = 1 end
	output[3] = heat or 3
	table.insert(KeyList, key)
	Recipes[key] = {
		input = input,
		output = output[1],
		number = tonumber(output[2]),
		heat = output[3],
	}
	NumRecipes = NumRecipes + 1
	print("register_recipe", key, dump(output))
end


ironage.register_recipe("default:cobble", "default:obsidian", 4)
ironage.register_recipe({"default:copper_lump", "default:mese_crystal_fragment"}, "default:gold_ingot", 3)