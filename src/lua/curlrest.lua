local curlrest = { _version = "0.0.1" }

local function protect_shell_args(curl_args)
    local protected_args = {}
    for _, arg in ipairs(curl_args) do
        -- Check if the argument contains shell special characters
        if arg:find('[%s|&<>;%(%){}`\'"]') then
            -- Escape existing double quotes in the argument
            arg = arg:gsub("'", "'\"'\"'")
            -- Add quotes around the argument
            arg = "'" .. arg .. "'"
        end
        table.insert(protected_args, arg)
    end
    return protected_args
end

local function char_to_percent(c)
    return string.format("%%%02X", string.byte(c))
end

function curlrest.percent_encode(value)
    value = value:gsub("([^%w ])", char_to_percent)
    value = value:gsub(" ", "+")
    return value
end

function curlrest.call(args)
    local curl_args = {}
    if args.basic_auth then
        table.insert(curl_args, "-u")
        table.insert(curl_args, args.basic_auth.username .. ":" .. args.basic_auth.password)
    end
    if args.data then
        table.insert(curl_args, "-d")
        table.insert(curl_args, args.data)
    end
    table.insert(curl_args, args.base_url .. "/" .. args.subpath)
    if args.method then
        table.insert(curl_args, "-X")
        table.insert(curl_args, args.method)
    end
    if args.headers then
        for key, value in pairs(args.headers) do
            table.insert(curl_args, "-H")
            table.insert(curl_args, key .. ": " .. value)
        end
    end
    -- no 100-Continue
    table.insert(curl_args, "-H")
    table.insert(curl_args, "Expect:")
    local command = "curl -isS " .. table.concat(protect_shell_args(curl_args), " ")
    if args.log_func then
        args.log_func("[" .. command .. "]")
    end
    local handle = assert(io.popen(command))
    local response = {
        status_code = nil,
        headers = {},
        body = nil
    }

    -- Read the output line by line and process each line
    for line in handle:lines() do
        line = line:gsub("\r", "")
        if args.log_func then
            args.log_func("[" .. line .. "]")
        end
        -- Check if the line is the status line (e.g., "HTTP/1.1 200 OK")
        if not response.status_code then
            --- "^HTTP/%d.%d%s%d+%s"
            local _, _, status_code = string.find(line, "HTTP/%d%.%d (%d+)")
            if status_code then
                response.status_code = tonumber(status_code)
            end
        elseif line == "" then
            -- Read the rest of the output as the body and we are done
            response.body = handle:read("*a")
            if args.log_func then
                args.log_func("[" .. response.body .. "]")
            end
            break
        else
            -- Split the line into key and value (e.g., "Content-Type: application/json")
            local key, value = line:match("([^:]+):%s*(.+)")
            if key and value then
                response.headers[key] = value
            end
        end
    end

    handle:close()

    -- TODO: decode JSON body if Content-Type is application/json

    return response
end

function rest_dump(log_func, response)
    log_func("Status Code:", response.status_code)
    log_func("Headers:")
    for key, value in pairs(response.headers) do
        log_func(key, ":", value)
    end
    log_func("Body:", response.body)
end

return curlrest
