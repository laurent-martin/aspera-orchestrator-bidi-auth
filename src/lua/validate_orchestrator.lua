--- Forward session validation to orchestrator
local json = require "json"
local curlrest = require "curlrest"
--- load configuration
local config = require "config_orchestrator"
--- load fwd application
local forward_orchestrator = require "forward_orchestrator"
--- Update parameters on current transfer session
local function update_transfer(tspec)
    return curlrest.call {
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
        data = json.encode(tspec),
        log_func = config.debug and lua_log or nil,
    }
end

--- stop transfer
update_transfer({ target_rate_kbps = 0 })

--- validate session, returns nil if validation is OK, error message otherwise
local message = forward_orchestrator(config)

if message then
    lua_session_abort(message)
else
    update_transfer({ target_rate_kbps = config.target_rate_kbps })
end
