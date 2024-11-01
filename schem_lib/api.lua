local extension = ".mtx"
local STOR_DIR = "schemlib"
local world_path = minetest.get_worldpath()

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
        local path = world_path .. "/" .. STOR_DIR
        minetest.mkdir(path)
        local filename = path .. "/" .. data.filename
        local file = io.open(filename .. extension, "w")

        file:write(sdata)
        file:close()
    end

    if flags.origin_clear and flags.origin_clear == true then
        minetest.after(10, function()
            schemlib.func.clear_position(pos1, pos2)
        end)
        minetest.after(30, function()
            schemlib.func.clear_position(pos1, pos2)
        end)
    end

    return sdata
end

-- Load from file using any directory
function schemlib.load_emitted(data)
    local path = world_path .. "/" .. STOR_DIR
    local filename = path .. "/" .. data.filename
    local file = io.open(filename .. extension, "r")
    if file then
        local count, ver, meta = schemlib.process_emitted(data.origin, file:read("*all"), nil, data.moveObj)
        file:close()
        return meta
    end
    return nil
end

-- Load from file using world directory
function schemlib.load_emitted_file(data)
    minetest.log(">>>> loading " .. data.filename)
    local file = io.open(data.filepath .. data.filename .. extension, "r")
    local content = ""
    local chunksize = 32768
    if file then
        local c = 0
        while true do
            local chunk = file:read(chunksize)
            if not chunk then
                break
            end
            minetest.log(">> Loaded chunk " .. c)
            c = c + 1
            content = content .. chunk
        end
        file:close()
    end
    -- local content = file:read("*all")
    minetest.log(">>>> File Loaded " .. data.filename)
    local count, ver, meta = schemlib.process_emitted(data.origin, content, nil, data.moveObj)

    minetest.log(">>> Emitted Load " .. data.filename)
    return meta
end
