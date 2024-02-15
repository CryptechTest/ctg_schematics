--- Converts the region defined by positions `pos1` and `pos2`
-- into a single string.
-- @return The serialized data.
-- @return The number of nodes serialized.
function schemlib.serialize(pos1, pos2)
    pos1, pos2 = schemlib.sort_pos(pos1, pos2)
    schemlib.keep_loaded(pos1, pos2)

    local get_node, get_meta, hash_node_position = minetest.get_node, minetest.get_meta, minetest.hash_node_position

    -- Find the positions which have metadata
    local has_meta = {}
    local meta_positions = minetest.find_nodes_with_meta(pos1, pos2)
    for i = 1, #meta_positions do
        has_meta[hash_node_position(meta_positions[i])] = true
    end

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
                local node = get_node(pos)
                if minetest.registered_nodes[node.name] == nil then
                    -- ignore
                elseif node.name ~= "air" and node.name ~= "ignore" and node.name ~= "vacuum:vacuum" and node.name ~=
                    "asteroid:atmos" then
                    count = count + 1

                    local meta
                    if has_meta[hash_node_position(pos)] then
                        meta = get_meta(pos):to_table()

                        -- Convert metadata item stacks to item strings
                        for _, invlist in pairs(meta.inventory) do
                            for index = 1, #invlist do
                                local itemstack = invlist[index]
                                if itemstack.to_string then
                                    invlist[index] = itemstack:to_string()
                                end
                            end
                        end
                    end

                    result[count] = {
                        x = pos.x - pos1.x,
                        y = pos.y - pos1.y,
                        z = pos.z - pos1.z,
                        name = node.name,
                        param1 = node.param1 ~= 0 and node.param1 or nil,
                        param2 = node.param2 ~= 0 and node.param2 or nil,
                        meta = meta
                    }
                end
                pos.z = pos.z + 1
            end
            pos.y = pos.y + 1
        end
        pos.x = pos.x + 1
    end
    return deepcopy(result), count
end

function schemlib.serialize_table(head, flags, pos1, pos2)
    local result, count = schemlib.serialize(pos1, pos2)
    -- Serialize entries
    local json_header = schemlib.get_serialized_header(head, count)
    local json_flags = schemlib.get_serialized_flags(flags)
    local table = {}
    local header = minetest.parse_json("{" .. json_header .. "}")
    table.meta = header.meta
    table.flags = minetest.parse_json(json_flags)
    table.cuboid = result
    return table, count
end

function schemlib.serialize_json(head, flags, pos1, pos2)
    local result, count = schemlib.serialize(pos1, pos2)
    -- Serialize entries
    local json_result = minetest.write_json(result)
    local json_header = schemlib.get_serialized_header(head, count)
    local json_flags = schemlib.get_serialized_flags(flags)
    local json_str = schemlib.format_result_json(json_header, json_flags, json_result)
    return json_str, count
end

local function load_json_schematic(value)
    local obj = {}
    if value then
        obj = minetest.parse_json(value)
        return obj
    end
    return obj
end

-- Internal
function allocate_with_nodes(origin_pos, nodes)
    local huge = math.huge
    local pos1x, pos1y, pos1z = huge, huge, huge
    local pos2x, pos2y, pos2z = -huge, -huge, -huge
    local origin_x, origin_y, origin_z = origin_pos.x, origin_pos.y, origin_pos.z
    for i, entry in ipairs(nodes) do
        local x, y, z = origin_x + entry.x, origin_y + entry.y, origin_z + entry.z
        if x < pos1x then
            pos1x = x
        end
        if y < pos1y then
            pos1y = y
        end
        if z < pos1z then
            pos1z = z
        end
        if x > pos2x then
            pos2x = x
        end
        if y > pos2y then
            pos2y = y
        end
        if z > pos2z then
            pos2z = z
        end
    end
    local pos1 = {
        x = pos1x,
        y = pos1y,
        z = pos1z
    }
    local pos2 = {
        x = pos2x,
        y = pos2y,
        z = pos2z
    }
    return pos1, pos2, #nodes
end

local function load_to_map(origin_pos, obj)
    local nodes = obj.cuboid
    local o = obj.meta.offset
    local origin_x, origin_y, origin_z = origin_pos.x, origin_pos.y, origin_pos.z
    local add_node, get_meta = minetest.add_node, minetest.get_meta
    -- local data = manip:get_data()
    for i, entry in ipairs(nodes) do
        entry.x, entry.y, entry.z = origin_x + (entry.x - o.x), origin_y + (entry.y - o.y), origin_z + (entry.z - o.z)
        -- Entry acts as both position and node
        add_node(entry, entry)

        if entry.meta then
            get_meta(entry):from_table(entry.meta)
        end
    end
end

--- Loads the nodes represented by string `value` at position `origin_pos`.
-- @return The number of nodes deserialized.
function schemlib.process_emitted(origin_pos, value, obj, moveObj)
    -- minetest.log(">>> Loading Emitted...")
    if obj == nil then
        obj = load_json_schematic(value)
    end
    local nodes = obj.cuboid
    if not nodes then
        return nil
    end
    if #nodes == 0 then
        return #nodes
    end

    if not origin_pos or origin_pos == nil then
        origin_pos = obj.meta.dest
    end

    -- minetest.log(">>> Emerging Emitted...")

    local pos1, pos2 = allocate_with_nodes(origin_pos, nodes)

    minetest.emerge_area(pos1, pos2, function(blockpos, action, calls_remaining, param)
        if calls_remaining == 0 then
            local manip, area = schemlib.keep_loaded(pos1, pos2)

            minetest.after(0, function()
                load_to_map(origin_pos, obj)
            end)

            if moveObj then
                minetest.after(2, function()
                    schemlib.jump_ship_move_contents(obj.meta)
                end)
            end
        end
    end)

    return #nodes, obj.version, obj.meta
end
