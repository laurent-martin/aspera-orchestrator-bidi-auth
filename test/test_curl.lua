print("Starting")
local curlrest = require "curlrest"
local config = require "config_orchestrator"
local xfer_path = 'ops/transfers'
local response = curlrest.call {
    basic_auth = {
        username = config.node_user,
        password = config.node_pass
    },
    base_url = config.node_url,
    subpath = xfer_path,
    data = "hello'",
    debug = true,
}
rest_dump(print, response)
