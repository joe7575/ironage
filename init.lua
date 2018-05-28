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
dofile(MP.."/lighter.lua")
dofile(MP.."/meltingpot.lua")
dofile(MP.."/tools.lua")
if minetest.global_exists("wielded_light") then
	dofile(MP.."/meridium.lua")
end

dofile(MP.."/recipes.lua")

