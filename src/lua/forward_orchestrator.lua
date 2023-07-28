local curlrest = require "curlrest"
local json = require "json"
--- Forward the LUA script to Orchestrator workflow
--- @param config table the configuration (base_url, username, password, workflow, debug)
-- env_table is a global variable
function forward_to_orchestrator(config)
    --lua_session_set_max_wait(0)
    if config.debug then
        lua_log("package.path=" .. package.path)
        for k, v in pairs(env_table) do
            if type(v) ~= 'number' then v = '"' .. v .. '"' end
            lua_log("env_table[\"" .. k .. "\"]=" .. tostring(v))
        end
    end
    --- send request to orchestrator with JSON payload (tags is a JSON in string)
    local response = curlrest.call {
        base_url = config.base_url,
        subpath = "external_calls/validate/" .. config.workflow .. "?login=" .. config.username .. "&password=" .. config.password,
        headers = {
            ["Content-Type"] = "application/json",
            ["Accept"] = "application/json"
        },
        debug = true,
        data = json.encode(env_table)
    }
    if response.status_code == 200 then
        if config.debug then
            lua_log("Validation: pass")
        end
        return nil
    end
    local error_message = "Cannot decode reason"
    if response.body and string.sub(response.body, 1, 1) == '{' then
        local data = json.decode(response.body)
        error_message = data.error.message
    end
    if config.debug then
        lua_log("Validation: KO: " .. error_message)
    end
    return error_message
end

return forward_to_orchestrator
