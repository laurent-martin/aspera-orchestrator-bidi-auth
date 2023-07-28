--- Forward session validation to orchestrator
--- load configuration
local config = require "config_orchestrator"
local json = require "json"
local curlrest = require "curlrest"
--- load fwd application
local forward_orchestrator = require "forward_orchestrator"
--- validate session, returns nil if validation is OK, error message otherwise
local message = forward_orchestrator(config)
if message then
    lua_session_abort(message)
else
    lua_log("Validation: pass")
    local response = curlrest.call {
        basic_auth = {
            username = config.node_user,
            password = config.node_pass
        },
        base_url = config.node_url,
        subpath = "ops/transfers/"..env_table["xfer_id"],
        headers = {
            ["Content-Type"] = "application/json",
            ["Accept"] = "application/json"
        },
        method = "PUT",
        data = json.encode({
            target_rate_kbps = 100000,
        }),
        debug = true,
    }
    rest_dump(lua_log, response)
end
