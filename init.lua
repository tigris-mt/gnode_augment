local M = {}
gnode_augment = M

M.players = {}

local function stop_standing(player)
	local data = M.players[player:get_player_name()]

	local node = minetest.get_node(data.standing)
	local def = minetest.registered_nodes[node.name]

	def._on_stop_standing(data.standing, node, player)
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
		}

		local stand_def = minetest.registered_nodes[data.nodes.stand.name]

		if data.standing and not vector.equals(data.standing, stand_pos) then
			stop_standing(player)
		end
		data.standing = stand_def._on_stop_standing and stand_pos or nil

		if stand_def._on_standing then
			stand_def._on_standing(stand_pos, data.nodes.stand, player)
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
		standing = nil,
	}
end)

minetest.register_on_leaveplayer(function(player)
	local data = M.players[player:get_player_name()]

	if data.standing then
		stop_standing(player)
	end

	M.players[player:get_player_name()] = nil
end)
