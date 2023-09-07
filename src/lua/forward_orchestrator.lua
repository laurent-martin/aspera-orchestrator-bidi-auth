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
    local call_path = "external_calls/validate/" .. config.orchestrator.workflow
    -- TODO: percent encode with curlrest.percent_encode values
    -- .. "?login=" .. config.orchestrator.user .. "&password=" .. config.orchestrator.pass
    local response = curlrest.call {
        base_url = config.orchestrator.url,
        subpath = call_path,
        headers = {
            ["Content-Type"] = "application/json",
            ["Accept"] = "application/json"
        },
        log_func = config.debug and lua_log or nil,
        data = json.encode(env_table)
    }
    if response.status_code == 200 then
        if config.debug then
            lua_log("Validation: pass")
        end
        return nil
    end
    local error_message = "Cannot decode reason (no JSON payload)"
    if response.body and string.sub(response.body, 1, 1) == '{' then
        local data = json.decode(response.body)
        if type(data.error) == "string" then
            error_message = data.error
        elseif type(data.error) == "table" and type(data.error.message) == "string" then
            error_message = data.error.message
        else
            error_message = response.body
        end
    end
    if config.debug then
        lua_log("Validation: KO: " .. error_message)
    end
    return error_message
end

return forward_to_orchestrator
