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
    local response = curlrest.call {
        base_url = config.node.url,
        subpath = "ops/transfers/" .. env_table["xfer_id"],
        basic_auth = {
            username = config.node.user,
            password = config.node.pass
        },
        headers = {
            ["Content-Type"] = "application/json",
            ["Accept"] = "application/json"
        },
        method = "PUT",
        data = json.encode({
            target_rate_kbps = config.target_rate_kbps,
        }),
        log_func = config.debug and lua_log or nil,
    }
end
