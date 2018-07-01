# Iron Age V0.03

Melting Pot for ingot/alloy smelting with coal burner and charcoal production.

Browse on: ![GitHub](https://github.com/joe7575/ironage)

Download: ![GitHub](https://github.com/joe7575/ironage/archive/master.zip)

With this mod new blocks, ingots and alloys can be made.  
The mod includes a Melting Pot (to complement the furnace). The pot must be heated with a coal burner.  
The charcoal must first be produced with the help of a charcoal burner (charcoal pile).  

![Iron Age](https://github.com/joe7575/ironage/blob/master/screenshot.png)

The Melting Pot inventory has a smelting guide and two construction tabs.

![Iron Age](https://github.com/joe7575/ironage/blob/master/meltingpod.png)

The mod includes per default only a few example recipes but can be extended by means of a recipe registration API.

Obsidian example:

```LUA
ironage.register_recipe({
	output = "default:obsidian", 
	recipe = {"default:cobble"}, 
	heat = 5,
	time = 4,
})
```

'output' and 'recipe' are similar to the standard crafting recipes. All ironage recipes are 'shapeless'.  
'recipe' is a list with up to four items.  
'heat' is the needed burner heat, which corresponds to the burner height/number of charcoal nodes (2..32)  
'time' is the smelting time in seconds (2..n)  


If the mod 'wielded_light' is installed, recipes for Meridium and Meridium tools are added.
Meridium is a glowing metal alloy to produce glowing tools.

If the mod 'unified_inventory' is installed, the recipes are also available via the unified_inventory crafting guide.


### Dependencies
default, fire, farming  
Optional: intllib, wielded_light, unified_inventory

### License
Copyright (C) 2018 Joachim Stolberg  
Code: Licensed under the GNU LGPL version 2.1 or later. See LICENSE.txt and http://www.gnu.org/licenses/lgpl-2.1.txt  
Textures: CC0

### History
- 2018-05-29  V0.01  * First version  
- 2018-06-09  V0.02  * Further recipes added  
- 2018-07-01  V0.03  * Minetest 0.5.0 bugfixes  