-- This script simulates the Aspera internal functions for LUA
env_table = {}
---stat data
stat_data = {}

aborted = true

function lua_err(m) print("ERR " .. m) end

function lua_log(m) print("LOG " .. m) end

function lua_dbg1(m) print("DG1 " .. m) end

function lua_dbg2(m) print("DG2 " .. m) end

function lua_dbg3(m) print("DG3 " .. m) end

function lua_dbg4(m) print("DG4 " .. m) end

---fill the stucture stat_data
---@param file string file path
---@return table stat_data
function lua_stat(file)
    stat_data = {}
    local file = io.open(file, 'rb')
    if file then
        file:close()
    end
    stat_data["exists"] = file ~= nil
    stat_data["size"] = 1000
    stat_data["blocks"] = 10
    stat_data["blocksize"] = 1024
    -- | "S_IFDIR" | "S_IFREG" | "S_IFCHR" |"S_IFBLK" | "S_IFIFO" | "S_IFSOCK" | "S_IFLNK" | "Block stream" | "Custom" | "Unknown"
    stat_data["type"] = "Invalid"
    stat_data["mode format"] = "Linux format" -- "Windows format" |
    stat_data["mode"] = "0777"                -- (format based on mode format above)
    stat_data["uid"] = 1
    stat_data["gid"] = 1
    stat_data["ctime"] = 1
    local f = assert(io.popen("stat -f %m " .. file))
    stat_data["mtime"] = f:read()
    stat_data["atime"] = 1
    return stat_data
end

---Rename the file
---@param old string current file path
---@param new string new file path
function lua_rename(old, new)
    os.rename(old, new)
end

function lua_file_delete(path)
    os.remove(path)
end

function lua_session_abort(message)
    print("simulator: lua_session_abort: " .. message)
    aborted = true
end

function lua_session_set_max_wait(seconds)
    print("simulator: lua_session_set_max_wait: not implemented")
end

local args = { ... }
if #args == 0 then
    print("Usage: provide test init scripts and program as arguments")
    return
end
-- execute provided init scripts and test program
for k, v in ipairs(args) do
    dofile(v)
end
-- display result
if aborted then
    print("similator: TRANSFER ABORTED")
    os.exit(1)
end
print("similator: TRANSFER CONTINUES")
os.exit(0)
