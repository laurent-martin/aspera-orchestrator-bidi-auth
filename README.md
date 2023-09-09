# Aspera transfer authorization using Orchestrator and LUA

This project uses the "LUA scripting" capability of the IBM Aspera HSTS (High Speed Transfer Server) to authorize transfers using the Orchestrator API.

The "inline validation" feature of HSTS works only for uploads.
This project allows to validate both uploads and downloads.
One issue, though, is that the LUA script execution is asynchronous, so the transfer is started at the same time the script is started.
So, the script first stops the transfer, then validates it, and restarts it if the validation is successful.

A LUA library is provided which allows starting the validation on Orchestrator using the same interface as "inline validation".

This LUA script takes the parameters received on LUA and forwards to Orchestrator.

## Components

The following scripts are used on HSTS:

- `validate_orchestrator.lua`: the main script to validate transfers
- `forward_orchestrator.lua`: a library to forward the parameters to Orchestrator
- `config_orchestrator.lua`: the configuration file for the main script

    This configuration file must be filled following the template `config_orchestrator.tmpl.lua`.
- `curlrest.lua`: a library to call REST APIs using `curl`
- `json.lua`: a library to parse JSON

    This library is downloaded from:

    <https://raw.githubusercontent.com/rxi/json.lua/master/json.lua>

## Manual Installation of the scripts

Place all the scripts listed previously in `/usr/local/share/lua/5.1/` on HSTS.

For example, to download the scripts from github:

```bash
for f in validate_orchestrator forward_orchestrator curlrest;do curl https://raw.githubusercontent.com/laurent-martin/aspera-orchestrator-bidi-auth/main/src/lua/$f.lua -o $f.lua;done
curl -so json.lua https://raw.githubusercontent.com/rxi/json.lua/master/json.lua
curl -so config_orchestrator.lua https://raw.githubusercontent.com/laurent-martin/aspera-orchestrator-bidi-auth/main/src/lua/config_orchestrator.lua.tmpl
```

Alternatively build the zip file, and extract.

Then, activate the script on HSTS with:

```bash
asconfigurator -x 'set_user_data;user_name,laurent;lua_session_start_script_path,/usr/local/share/lua/5.1/validate_orchestrator.lua'
```

## Setup on HSTS

Create a specific transfer user that will handle validation for cases when validation is needed.

An access key can also be used, but all transfers for access keys use transfer user `xfer` by default, so any access key based transfer would trigger validation.

An additional check can be made in the LUA part to bypass validation in specific cases.

If a specific transfer user is needed, together with a node API user:

```bash
xferuser=my_xfer_user
useradd $xferuser
useradd --create-home --no-user-group --shell /bin/aspshell $xferuser
passwd --lock $xferuser
chage --mindays 0 --maxdays 99999 --inactive -1 --expiredate -1 $xferuser
askmscli --init-keystore --user=$xferuser
mkdir -p /home/$xferuser/.ssh
cp /opt/aspera/var/aspera_tokenauth_id_rsa.pub /home/$xferuser/.ssh/authorized_keys
chmod -R go-rwx /home/$xferuser/.ssh
chown -R $xferuser: /home/$xferuser
asnodeadmin -a -u my_node_user -p my_pass -x $xferuser
asconfigurator << EOF
set_user_data
user_name,$xferuser
authorization_transfer_in_value,token
authorization_transfer_out_value,token

terminate
EOF
asnodeadmin --reload
```

Activate the LUA script on HSTS with:

```bash
asconfigurator -x "set_user_data;user_name,$xferuser,lua_session_start_script_path,/usr/local/share/lua/5.1/validate_orchestrator.lua"
```

## Automated Installation

A zip file containing necessary LUA scripts can be built: `make zip`.
The archive consists in the LUA scripts listed previously.

For automation, create a shell script: `private/config.sh`

Scripts can be installed with:

```bash
make deploy
```

## Logging

LUA logs are sent to the same logs as `ascp`, typically `/var/log/aspera.log` or `/var/log/messages`, with prefix `lua:`.

Debug information can be activated with parameter: `debug = true` in the configuration file, or de-active with `debug = false`.

> **Note:** No service restart is required to activate debug, as the script is reloaded at each transfer.
