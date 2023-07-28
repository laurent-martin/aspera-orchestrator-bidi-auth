# Aspera transfer authorization using Orchestrator and LUA

This LUA script takes the parameters received on LUA and forwards to Orchestrator.

The process is asynchronous.

## Installation

Look at the recipe in the `Makefile`s.

Download the file: <https://raw.githubusercontent.com/rxi/json.lua/master/json.lua>

> **Note:** In the following text `*` refers to either `local` or `orchestrator`.

Copy the configuration file: `config_*.tmpl` to `config_*.lua` and customize.

The list of files to deploy is in: `DEPLOY_SCRIPTS`, to be deployed on HSTS in `/usr/local/share/lua/5.1`.

The validation script is identified by `MAIN_SCRIPT` and should be assigned to the transfer user:

```bash
asconfigurator -x 'set_user_data;user_name,laurent;lua_session_start_script_path,/usr/local/share/lua/5.1/validate_*.lua'
```

## Logs

LUA logs are sent to the same logs as `ascp`, typically `/var/log/aspera.log` or `/var/log/messages`, with prefix `lua:`.

## Setup on HSTS

Create a specific transfer user that will handle validation.
An access could be used, but that would not allow setting a default speed of zero for that use case only.

```bash
xferuser=my_xfer_user
useradd $xferuser
asnodeadmin -a -u my_node_user -p my_pass -x $xferuser
asconfigurator << EOF
set_user_data
user_name,$xferuser
authorization_transfer_in_value,token
authorization_transfer_out_value,token
transfer_in_bandwidth_flow_target_rate_default,1
transfer_out_bandwidth_flow_target_rate_default,1
lua_session_start_script_path,/usr/local/share/lua/5.1/validate_orchestrator.lua

terminate
EOF
asnodeadmin --reload
```
