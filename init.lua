-- display_biome
-- Adds HUD display of current mapgen biome information.
--
-- by David G (kestral246@gmail.com)
-- 2019-12-06
--
-- Add chat command /biomes

display_biome = {}
local storage = minetest.get_mod_storage()

minetest.register_on_joinplayer(function(player)
	local pname = player:get_player_name()
	if storage:get(pname) and storage:get(pname) == "1" then  -- enabled
		display_biome[pname] = {
			last_ippos = {x=0,y=0,z=0},
			id = player:hud_add({
				hud_elem_type = "text",
				position = {x=0.5, y=0.1},
				text = "-",
				number = 0xFF0000,  -- red text
			}),
			enable = true }
	else  -- not enabled
		display_biome[pname] = {
			last_ippos = {x=0,y=0,z=0},
			id = player:hud_add({
				hud_elem_type = "text",
				position = {x=0.5, y=0.1},
				text = "",
				number = 0xFF0000,  -- red text
			}),
			enable = false }
	end
end)

minetest.register_chatcommand("biomes", {
	params = "",
	description = "Toggle display of biome data.",
	privs = {},
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if display_biome[name].enable == true then
			player:hud_change(display_biome[name].id, "text", "")
			display_biome[name].enable = false
			storage:set_string(name, "0")
		else
			player:hud_change(display_biome[name].id, "text", "-")
			display_biome[name].enable = true
			storage:set_string(name, "1")
		end
	end,
})

minetest.register_on_leaveplayer(function(player)
	local pname = player:get_player_name()
	if display_biome[pname] then
		display_biome[pname] = nil
	end
end)

local timer = 0

minetest.register_globalstep(function(dtime)
	timer = timer + dtime
	if timer < 0.5 then
		return
	end

	timer = 0

	for _, player in ipairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		if display_biome[pname].enable == true then
			local ppos = player:get_pos()
			local ippos = {x=math.floor(ppos.x),y=math.floor(ppos.y),z=math.floor(ppos.z)}  -- integer position
			local bpos = {x=ippos.x,y=ippos.y,z=ippos.z}  -- surface position at which to calculate biome
	
			if not (ippos.x == display_biome[pname].last_ippos.x and ippos.y == display_biome[pname].last_ippos.y and ippos.z == display_biome[pname].last_ippos.z) then  -- position changed
				-- simple search for ground elevation
				while bpos.y > 0 and minetest.get_node(bpos).name == "air" do
					bpos.y = bpos.y - 1
				end
	
				if minetest.get_biome_data(bpos) and minetest.get_biome_data(bpos).biome then
					local bdata = minetest.get_biome_data(bpos)
	
					player:hud_change(display_biome[pname].id, "text",
						'temp = '..math.floor(bdata.heat + 0.5)..
						', humid = '..math.floor(bdata.humidity + 0.5)..
						', '..minetest.get_biome_name(bdata.biome))
					display_biome[pname].last_ippos = {x=ippos.x,y=ippos.y,z=ippos.z}  -- update last player position
				end
			end
		end
	end
end)

