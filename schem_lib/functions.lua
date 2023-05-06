function schemlib.clear_position(pos1, pos2)
    -- schemlib.keep_loaded(pos1, pos2)
    pos1, pos2 = schemlib.sort_pos(pos1, pos2)
    local pos = {
        x = pos1.x,
        y = 0,
        z = 0
    }
    local count = 0
    local result = {}
    while pos.x <= pos2.x do
        pos.y = pos1.y
        while pos.y <= pos2.y do
            pos.z = pos1.z
            while pos.z <= pos2.z do
                local node = minetest.get_node(pos)
                if node.name ~= "air" and node.name ~= "ignore" then
                    count = count + 1

                    minetest.set_node(pos, {
                        name = "vacuum:atmos_thin"
                    })

                end
                pos.z = pos.z + 1
            end
            pos.y = pos.y + 1
        end
        pos.x = pos.x + 1
    end
    return count
end

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local square = math.sqrt;
local get_distance = function(a, b)
    local x, y, z = a.x - b.x, a.y - b.y, a.z - b.z
    return square(x * x + y * y + z * z)
end

local function do_particles(pos)
    local prt = {
        texture = "ctg_jetpack_vapor_cloud.png",
        texture_r180 = "ctg_jetpack_vapor_cloud.png" .. "^[transformR180",
        vel = 0.6,
        time = 7,
        size = 6,
        glow = 3,
        cols = false
    }
    local exm = pos
    exm.y = exm.y + 1.5
    local rx = math.random(-0.01, 0.01) * 0.5
    local rz = math.random(-0.01, 0.01) * 0.5
    local texture = prt.texture
    if (math.random() >= 0.6) then
        texture = prt.texture_r180
    end
    local v = vector.new()
    minetest.add_particle({
        pos = exm,
        velocity = {
            x = rx,
            y = prt.vel * -math.random(0.2 * 100, 0.7 * 100) / 100,
            z = rz
        },
        minacc = {
            x = -0.02,
            y = -0.05,
            z = -0.02
        },
        maxacc = {
            x = 0.02,
            y = -0.03,
            z = 0.02
        },
        expirationtime = ((math.random() / 5) + 0.25) * prt.time,
        size = ((math.random()) * 7 + 0.1) * prt.size,
        collisiondetection = prt.cols,
        vertical = false,
        texture = texture,
        glow = prt.glow
    })
end

function schemlib.jump_ship_move_contents(lmeta)
    local pos = lmeta.origin
    local dest = lmeta.dest
    local dist_travel = get_distance(pos, dest)
    local dist_x = 0
    local dist_y = 0
    local dist_z = 0

    if pos.x >= dest.x then
        dist_x = -(pos.x - dest.x)
    elseif pos.x < dest.x then
        dist_x = dest.x - pos.x
    end
    if pos.y >= dest.y then
        dist_y = -(pos.y - dest.y)
    elseif pos.y < dest.y then
        dist_y = dest.y - pos.y
    end
    if pos.z >= dest.z then
        dist_z = -(pos.z - dest.z)
    elseif pos.z < dest.z then
        dist_z = dest.z - pos.z
    end

    local pos1 = vector.subtract(pos, {
        x = lmeta.offset.x,
        y = lmeta.offset.y,
        z = lmeta.offset.z
    })
    local pos2 = vector.add(pos, {
        x = lmeta.offset.x,
        y = lmeta.offset.y,
        z = lmeta.offset.z
    })

    -- get cube of area nearby
    local objects = minetest.get_objects_in_area(pos1, pos2) or {}
    for _, obj in pairs(objects) do
        if obj then
            local new_pos = vector.add(obj:get_pos(), {
                x = dist_x,
                y = dist_y,
                z = dist_z
            })
            if obj:is_player() then
                local player = minetest.get_player_by_name(obj:get_player_name())
                if player.send_mapblock then
                    for x = -1, 1 do
                        for y = -1, 1 do
                            for z = -1, 1 do
                                player:send_mapblock(vector.divide({
                                    x = new_pos.x + (16 * x),
                                    y = new_pos.y + (16 * y),
                                    z = new_pos.z + (16 * z)
                                }, 16))
                            end
                        end
                    end
                    -- minetest.log("send_mapblock " .. tostring(sent))
                end
                for i = 1, 3 do
                    minetest.after(i, function()
                        for i = 1, 20 do
                            local p = {
                                x = new_pos.x + math.random(-6, 6),
                                y = new_pos.y + math.random(-2, 4),
                                z = new_pos.z + math.random(-6, 6)
                            }
                            do_particles(p)
                        end
                    end)
                end
                minetest.after(0.5, function()
                    obj:set_pos(new_pos)
                end)
            else
                obj:set_pos(new_pos)
            end
        end
    end

    return dist_travel
end
