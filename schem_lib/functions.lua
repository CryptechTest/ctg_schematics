-- functions
schem_lib.func = {}

-- get static spawn position
local statspawn = minetest.string_to_pos(minetest.settings:get("static_spawnpoint")) or {
    x = 0,
    y = 2,
    z = 0
}
-- spawn protection
local protector_spawn = tonumber(minetest.settings:get("protector_spawn")) or 250

-- check if pos is inside a protected spawn area
local inside_spawn = function(pos, radius)
    if protector_spawn <= 0 then
        return false
    end
    if pos.x < statspawn.x + radius and pos.x > statspawn.x - radius and pos.y < statspawn.y + radius and pos.y >
        statspawn.y - radius and pos.z < statspawn.z + radius and pos.z > statspawn.z - radius then
        return true
    end
    return false
end

function schem_lib.func.clear_position(pos1, pos2)
    pos1, pos2 = schem_lib.common.sort_pos(pos1, pos2)
    local count = 0
    local c_vaccuum = minetest.get_content_id("vacuum:vacuum")
    local c_ignore = minetest.get_content_id("ignore")
    local vm = VoxelManip(pos1, pos2)
    local pmin, pmax= vm:read_from_map(pos1, pos2)
    local area = VoxelArea:new({MinEdge = pmin, MaxEdge = pmax})
    local data = vm:get_data()

    for z = pos1.z, pos2.z do
        for y = pos1.y, pos2.y do
            for x = pos1.x, pos2.x do

                local index = area:index(x, y, z)
                if data[index] ~= c_ignore then
                    data[index] = c_vaccuum
                    count = count + 1
                end
            end
        end
    end
    vm:set_data(data)
    vm:write_to_map()
    return count
end

local square = math.sqrt;
local get_distance = function(a, b)
    local x, y, z = a.x - b.x, a.y - b.y, a.z - b.z
    return square(x * x + y * y + z * z)
end

local function do_particles(pos)
    local prt = {
        texture = {
            name = "ctg_schem_vapor_cloud.png",
            fade = "out"
        },
        texture_r180 = {
            name = "ctg_schem_vapor_cloud.png" .. "^[transformR180",
            fade = "out"
        },
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

local function do_particle_zap(pos, amount)
    local texture = {
        name = "ctg_tele_zap_anim.png",
        fade = "out"
    }
    local animation = {
        type = "vertical_frames",
        aspect_w = 64,
        aspect_h = 64,
        length = 0.27
    }
    -- spawn particle
    minetest.add_particlespawner({
        amount = amount,
        time = math.random(0.5, 0.7),
        minpos = {
            x = pos.x - 0.2,
            y = pos.y - 0.15,
            z = pos.z - 0.2
        },
        maxpos = {
            x = pos.x + 0.2,
            y = pos.y + 0.42,
            z = pos.z + 0.2
        },
        minvel = {
            x = 0,
            y = 0,
            z = 0
        },
        maxvel = {
            x = 0,
            y = 0.15,
            z = 0
        },
        minacc = {
            x = -0,
            y = -0.1,
            z = -0
        },
        maxacc = {
            x = 0,
            y = 0.25,
            z = 0
        },
        minexptime = 0.28,
        maxexptime = 0.46,
        minsize = 20,
        maxsize = 28,
        collisiondetection = false,
        collision_removal = false,
        object_collision = false,
        animation = animation,
        texture = texture,
        glow = 15
    })
end

function schem_lib.func.update_screens(pos1, pos2)
    if core.get_modpath("digiterms") == nil then
        return
    end
    local screens = core.find_nodes_in_area(pos1, pos2, "group:display_api")
    if screens == nil or #screens == 0 then
        return
    end
    for _, scrnpos in pairs(screens) do
        local node = core.get_node(scrnpos)
        if node ~= nil then
            local meta = core.get_meta(scrnpos)
            local msg = meta and meta:get_string("display_text") or nil
            if msg then
                digiterms.push_text_on_screen(scrnpos, msg)
            end
        end
    end
end

function schem_lib.func.jump_ship_move_contents(lmeta)
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
                        for i = 1, 3 do
                            local p = {
                                x = new_pos.x + math.random(-6, 6),
                                y = new_pos.y + math.random(-2, 4),
                                z = new_pos.z + math.random(-6, 6)
                            }
                            do_particles(p)
                        end
                    end)
                end
                obj:set_pos(new_pos)
                minetest.after(0, function()
                    obj:set_pos(new_pos)
                    do_particle_zap(new_pos, 2)
                end)
            else
                local ent = obj:get_luaentity()
                local rem = false
                if ent then
                    if ent.name == "digiterms:screen" then
                        obj:remove()
                        rem = true
                    elseif ent.name == "3d_armor_stand:armor_entity" then
                        obj:remove()
                        rem = true
                    end
                end
                if not rem then
                    obj:set_pos(new_pos)
                end
            end
        end
    end

    return dist_travel
end

function schem_lib.func.jump_ship_emit_player(lmeta, arriving)
    local pos = lmeta.origin
    local dest = lmeta.dest
    local dist_travel = get_distance(pos, dest)

    local _pos = not arriving and pos or dest

    local pos1 = vector.subtract(_pos, {
        x = lmeta.offset.x,
        y = lmeta.offset.y,
        z = lmeta.offset.z
    })
    local pos2 = vector.add(_pos, {
        x = lmeta.offset.x,
        y = lmeta.offset.y,
        z = lmeta.offset.z
    })

    -- get cube of area nearby
    local objects = minetest.get_objects_in_area(pos1, pos2) or {}
    for _, obj in pairs(objects) do
        if obj then
            if obj:is_player() then
                local player = minetest.get_player_by_name(obj:get_player_name())
                if not arriving then
                    player:set_physics_override({
                        gravity = 0
                    })
                else
                    otherworlds.gravity.reset(player)
                end
            end
        end
    end

    return dist_travel
end

local function emerge_callback(pos, action, num_calls_remaining, context)
    -- On first call, record number of blocks
    if not context.total_blocks then
        context.total_blocks = num_calls_remaining + 1
        context.loaded_blocks = 0
    end

    -- Increment number of blocks loaded
    context.loaded_blocks = context.loaded_blocks + 1

    -- Send progress message
    if context.total_blocks == context.loaded_blocks then
        -- minetest.chat_send_all("Finished loading blocks!")
    else
        local perc = 100 * context.loaded_blocks / context.total_blocks
        local msg = string.format("Loading blocks %d/%d (%.2f%%)", context.loaded_blocks, context.total_blocks, perc)
        -- minetest.chat_send_all(msg)
    end
end

function schem_lib.func.check_dest_clear(pos, dest, size)

    local pos1 = vector.subtract(dest, {
        x = size.w,
        y = size.h,
        z = size.l
    })
    local pos2 = vector.add(dest, {
        x = size.w,
        y = size.h,
        z = size.l
    })

    for z = pos1.z, pos2.z do
        for y = pos1.y, pos2.y do
            for x = pos1.x, pos2.x do
                local p = vector.new(x, y, z)
                -- is spawn area protected ?
                if inside_spawn(p, protector_spawn) then
                    return false
                end
            end
        end
    end

    local c_vacuum = minetest.get_content_id("vacuum:vacuum")
    local c_atmos = minetest.get_content_id("vacuum:atmos_thin")
    local c_atmos2 = minetest.get_content_id("asteroid:atmos")
    local c_ignore = minetest.get_content_id("ignore")

    local manip = minetest.get_voxel_manip()
    local e1, e2 = manip:read_from_map(pos1, pos2)
    local area = VoxelArea:new({
        MinEdge = e1,
        MaxEdge = e2
    })
    local data = manip:get_data()

    local vol = 0
    local count = 0
    local ignore = 0
    for z = pos1.z, pos2.z do
        for y = pos1.y, pos2.y do
            for x = pos1.x, pos2.x do

                vol = vol + 1
                local index = area:index(x, y, z)
                if data[index] == c_ignore then
                    ignore = ignore + 1
                elseif data[index] == c_vacuum then
                    count = count + 1
                elseif data[index] == c_atmos then
                    -- count = count + 1
                elseif data[index] == c_atmos2 then
                    count = count + 1
                end

            end
        end
    end

    if ignore > 0 and count == 0 then
        local context = {} -- persist data between callback calls
        minetest.emerge_area(pos1, pos2, emerge_callback, context)

        return false
    end

    if count == vol and ignore == 0 then
        return true
    end

    return false
end


local function find_nodes(pos, r, search)
    local nodes = minetest.find_nodes_in_area({
        x = pos.x - r,
        y = pos.y - r,
        z = pos.z - r
    }, {
        x = pos.x + r,
        y = pos.y + r,
        z = pos.z + r
    }, search)
    return nodes
end

local dist_rules = {
    {x= 0,y= 0,z= 0}, -- center point
    {x= 1,y= 0,z= 0},{x=-1,y= 0,z= 0}, -- along x beside
    {x= 0,y= 0,z= 1},{x= 0,y= 0,z=-1}, -- along z beside
    {x= 0,y= 1,z= 0},{x= 0,y=-1,z= 0}, -- along y above/below
    {x= 1,y= 1,z= 0},{x=-1,y= 1,z= 0}, -- 1 node above along x diagonal
    {x= 0,y= 1,z= 1},{x= 0,y= 1,z=-1}, -- 1 node above along z diagonal
    {x= 1,y=-1,z= 0},{x=-1,y=-1,z= 0}, -- 1 node below along x diagonal
    {x= 0,y=-1,z= 1},{x= 0,y=-1,z=-1}, -- 1 node below along z diagonal

    {x= 1,y= 0,z= 1},{x=-1,y= 0,z= 1}, -- corners beside
    {x= 1,y= 0,z=-1},{x=-1,y= 0,z=-1}, -- corners beside

    {x= 1,y= 1,z= 1},{x=-1,y= 1,z= 1}, -- corners above
    {x=-1,y= 1,z=-1},{x= 1,y= 1,z=-1}, -- corners above
    {x= 1,y=-1,z=-1},{x=-1,y=-1,z= 1}, -- corners below
    {x=-1,y=-1,z=-1},{x= 1,y=-1,z= 1}, -- corners below
}

local dist_rules2 = {
    {x= 0,y= 0,z= 0}, -- center point
    {x= 1,y= 0,z= 0},{x=-1,y= 0,z= 0}, -- along x beside
    {x= 0,y= 0,z= 1},{x= 0,y= 0,z=-1}, -- along z beside
    {x= 0,y= 1,z= 0},{x= 0,y=-1,z= 0}, -- along y above/below
    {x= 1,y= 1,z= 0},{x=-1,y= 1,z= 0}, -- 1 node above along x diagonal
    {x= 0,y= 1,z= 1},{x= 0,y= 1,z=-1}, -- 1 node above along z diagonal
    {x= 1,y=-1,z= 0},{x=-1,y=-1,z= 0}, -- 1 node below along x diagonal
    {x= 0,y=-1,z= 1},{x= 0,y=-1,z=-1}, -- 1 node below along z diagonal
}

function schem_lib.func.find_nodes_large(origin, size, search, options)
    local limit = (options and options.limit) or 1
    local dir = (options and options.dir) or {x = 0, y = 0, z = 0}
    local origin_offset = vector.add(origin, vector.multiply(dir, 80))
    if size < 80 then
        local xnodes = find_nodes(origin_offset, size, search)
        local nodes = {}
        for _, n in pairs(xnodes) do
            local dist = vector.distance(origin, n)
            if dist <= size then
                table.insert(nodes, {node = n, dist = dist})
            end
        end
        local function compare(a,b)
            return a.dist < b.dist
        end
        table.sort(nodes, compare)
        return nodes
    end
    local rem = size % 79
    local xnodes = {}
    for i, rule in pairs(dist_rules2) do
        local rs = vector.multiply(rule, (i == 0 and 80) or (80 + rem * 2))
        local pos = vector.add(origin_offset, rs)
        local fnodes = find_nodes(pos, 79, search)
        for _, n in pairs(fnodes) do
            table.insert(xnodes, n)
        end
        if #fnodes >= limit then
            break;
        end
    end
    local nodes = {}
    for _, n in pairs(xnodes) do
        local dist = vector.distance(origin, n)
        if dist <= size then
            table.insert(nodes, {pos = n, dist = dist})
        end
    end
    local function compare(a,b)
        return a.dist < b.dist
      end
    table.sort(nodes, compare)
    return nodes
end