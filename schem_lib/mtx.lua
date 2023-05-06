local extension = ".mtx"
local STOR_DIR = "schemlib"
local world_path = minetest.get_worldpath()

schemlib.LATEST_SERIALIZATION_VERSION = 6
local LATEST_SERIALIZATION_HEADER = "\"version\":" .. schemlib.LATEST_SERIALIZATION_VERSION
local SERIALIZATION_FORMAT = "\"format\":" .. "\"json\""
local SERIALIZATION_TYPE = "\"type\":" .. "\"schematic.ctg\""

function schemlib.get_serialized_header(head, count)
    local timestamp = "\"timestamp\":" .. os.time()
    local count = "\"count\":" .. count
    local offset = "\"offset\":" .. minetest.write_json(head.offset)
    local origin = "\"origin\":{}"
    if (head.origin) then
        origin = "\"origin\":" .. minetest.write_json(head.origin)
    end
    local dest = "\"dest\":{}"
    if head.dest then
        dest = "\"dest\":" .. minetest.write_json(head.dest)
    end
    local owner = "\"owner\":" .. "\"\""
    if head.owner then
        owner = "\"owner\":" .. minetest.write_json(head.owner)
    end
    local ttl = "\"ttl\":" .. head.ttl
    local metadata = "\"meta\":{" .. owner .. "," .. timestamp .. "," .. ttl .. "," .. count .. "," .. offset .. "," ..
                         origin .. "," .. dest .. "}"
    -- create header
    local header = SERIALIZATION_TYPE .. "," .. SERIALIZATION_FORMAT .. "," .. LATEST_SERIALIZATION_HEADER .. "," ..
                       metadata
    return header
end

function schemlib.get_serialized_flags(flags)
    local use_inv = "\"keep_inv\":" .. tostring(flags.keep_inv)
    local use_meta = "\"keep_meta\":" .. tostring(flags.keep_meta)
    local origin_clear = "\"origin_clear\":" .. tostring(flags.origin_clear)
    local file_cache = "\"file_cache\":" .. tostring(flags.file_cache)
    -- create flags
    local value = "{" .. use_inv .. "," .. use_meta .. "," .. origin_clear .. "," .. file_cache .. "}"
    local key = "\"flags\":"
    return key .. value
end

function schemlib.format_result_json(json_header, json_flags, result)
    local json_result = "\"cuboid\":" .. result
    local json_str = "{" .. json_header .. "," .. json_flags .. "," .. json_result .. "}"
    return json_str
end

-- Save to file
function schemlib.emit(data, flags)
    local pos1 = vector.subtract(data.origin, {
        x = data.w,
        y = data.h,
        z = data.l
    })
    local pos2 = vector.add(data.origin, {
        x = data.w,
        y = data.h,
        z = data.l
    })
    data.offset = {}
    data.offset.x = data.w
    data.offset.y = data.h
    data.offset.z = data.l

    local sdata, count = {}, 0
    if flags.file_cache then
        sdata, count = schemlib.serialize_json(data, flags, pos1, pos2)
    else
        sdata, count = schemlib.serialize_table(data, flags, pos1, pos2)
    end

    if flags.file_cache and flags.file_cache == true then
        local path = world_path .. DIR_DELIM .. STOR_DIR
        minetest.mkdir(path)
        local filename = path .. DIR_DELIM .. data.filename
        local file = io.open(filename .. extension, "w")

        file:write(sdata)
        file:close()
    end

    if flags.origin_clear and flags.origin_clear == true then
        minetest.after(10, function()
            schemlib.clear_position(pos1, pos2)
        end)
    end

    return sdata
end

-- Load from file
function schemlib.load_emitted(data)
    local path = world_path .. DIR_DELIM .. STOR_DIR
    local filename = path .. DIR_DELIM .. data.filename
    local file = io.open(filename .. extension, "r")
    local count, ver, meta = schemlib.process_emitted(data.origin, file:read("*all"), nil, data.moveObj)
    file:close()
    return meta
end
