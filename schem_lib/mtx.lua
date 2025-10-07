schemlib.LATEST_SERIALIZATION_VERSION = 9
local LATEST_SERIALIZATION_HEADER = "\"version\":" .. schemlib.LATEST_SERIALIZATION_VERSION
local SERIALIZATION_FORMAT = "\"format\":" .. "\"json\""
local SERIALIZATION_TYPE = "\"type\":" .. "\"schematic.ctg\""

function schemlib.get_serialized_header(head, count)
    local timestamp = "\"timestamp\":" .. os.time()
    local count = "\"count\":" .. count
    local offset = "\"offset\":" .. core.write_json(head.offset)
    local origin = "\"origin\":{}"
    if (head.origin) then
        origin = "\"origin\":" .. core.write_json(head.origin)
    end
    local dest = "\"dest\":{}"
    if head.dest then
        dest = "\"dest\":" .. core.write_json(head.dest)
    end
    local size = "\"size\":" .. core.write_json(head.size)
    local volume = "\"volume\":" .. core.write_json(head.volume)
    local owner = "\"owner\":" .. "\"\""
    if head.owner then
        owner = "\"owner\":" .. core.write_json(head.owner)
    end
    local ttl = "\"ttl\":" .. head.ttl
    local metadata = "\"meta\":{" .. owner .. "," .. timestamp .. "," .. ttl .. "," .. count .. "," .. offset .. "," ..
                         size .. "," .. volume .. "," .. origin .. "," .. dest .. "}"
    -- create header
    local header = SERIALIZATION_TYPE .. "," .. SERIALIZATION_FORMAT .. "," .. LATEST_SERIALIZATION_HEADER .. "," ..
                       metadata
    return header
end

function schemlib.get_serialized_flags(flags)
    local file_cache = "\"file_cache\":" .. tostring(flags.file_cache)
    local use_inv = "\"keep_inv\":" .. tostring(flags.keep_inv)
    local use_meta = "\"keep_meta\":" .. tostring(flags.keep_meta)
    local origin_clear = "\"origin_clear\":" .. tostring(flags.origin_clear)
    local keep_timers = "\"keep_timers\":" .. tostring(flags.keep_timers)
    local stop_timers = "\"stop_timers\":" .. tostring(flags.stop_timers)
    -- create flags
    local value = "{" .. file_cache .. "," .. use_inv .. "," .. use_meta .. "," ..
                        origin_clear .. "," .. keep_timers .. "," .. stop_timers .. "}"
    local key = "\"flags\":"
    -- create key-value
    return key .. value
end

function schemlib.format_result_json(json_header, json_flags, result)
    local json_result = "\"cuboid\":" .. result
    local json_str = "{" .. json_header .. "," .. json_flags .. "," .. json_result .. "}"
    return json_str
end
