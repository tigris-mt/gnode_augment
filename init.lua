local M = {}
gnode_augment = M

M.players = {}

local callbacks = {}

function M.register_callback(f)
	table.insert(callbacks, f)
	return #callbacks
end

function M.remove_callback(idx)
	table.remove(callbacks, idx)
end

local step_time = tonumber(minetest.settings:get("gnode_augment.step_time")) or 0.3
local timer = 0
minetest.register_globalstep(function(dtime)
	timer = timer + dtime
	if timer < step_time then
		return
	end
	timer = 0

	for _,player in ipairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local prop = player:get_properties()
		local data = M.players[name]
		local pos = player:get_pos()

		local stand_pos = vector.round(vector.add(pos, vector.new(0, -0.1, 0)))

		data.nodes = {
			top = minetest.get_node(vector.add(pos, vector.new(0, prop.eye_height, 0))),
			bottom = minetest.get_node(vector.add(pos, vector.new(0, prop.stepheight / 2, 0))),
			stand = minetest.get_node(stand_pos),
			stand_pos = stand_pos,
		}

		local stand_def = minetest.registered_nodes[data.nodes.stand.name]
		if stand_def._on_standing then
			stand_def._on_standing(stand_pos, data.nodes.stand, player)
		end

		for _,f in ipairs(callbacks) do
			f(player, data)
		end
	end
end)

local ignore = {
	name = "ignore",
	param1 = 0,
	param2 = 0,
}
minetest.register_on_joinplayer(function(player)
	M.players[player:get_player_name()] = {
		nodes = {
			top = ignore,
			bottom = ignore,
			stand = ignore,
		},
	}
end)

minetest.register_on_leaveplayer(function(player)
	M.players[player:get_player_name()] = nil
end)
