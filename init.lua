-- display_biome
-- Adds HUD display of current mapgen biome information.
--
-- by David G (kestral246@gmail.com)
-- 2020-01-01
--
-- Add chat command /biomes
-- Add support for v6 using Wuzzy's biomeinfo mod

display_biome = {}
local storage = minetest.get_mod_storage()

-- Optional V6 Support
local is_v6 = minetest.get_mapgen_setting("mg_name") == "v6" and minetest.get_modpath("biomeinfo") ~= nil

-- Configuration option
local start_enabled = minetest.settings:get_bool("display_biome_enabled", false)

minetest.register_on_joinplayer(function(player)
	local pname = player:get_player_name()
	if (storage:get(pname) and storage:get(pname) == "1") or start_enabled then  -- enabled
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
			local ippos = vector.round(player:get_pos())  -- integer position
			local bpos = vector.new(ippos)  -- surface position at which to calculate biome

			if not vector.equals(ippos, display_biome[pname].last_ippos) then  -- position changed
				-- simple search for ground elevation
				while bpos.y > 0 and minetest.get_node(bpos).name == "air" do
					bpos.y = bpos.y - 1
				end

				local heat, humidity, name
				if is_v6 then
					heat = math.floor(biomeinfo.get_v6_heat(bpos) * 100 + 0.5)/100
					humidity = math.floor(biomeinfo.get_v6_humidity(bpos) * 100 + 0.5)/100
					name = biomeinfo.get_v6_biome(bpos)
				else
					local bdata = minetest.get_biome_data(bpos)
					heat = math.floor(bdata.heat + 0.5)
					humidity = math.floor(bdata.humidity + 0.5)
					name = minetest.get_biome_name(bdata.biome)
				end
				player:hud_change(display_biome[pname].id, "text",
					'temp = '..heat..', humid = '..humidity..', '..name)
				display_biome[pname].last_ippos = vector.new(ippos)  -- update last player position
			end
		end
	end
end)

