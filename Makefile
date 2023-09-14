DIR_TOP=./
DIR_GEN=$(DIR_TOP)generated/
DIR_PRIV=$(DIR_TOP)private/
DIR_LUA_SRC=$(DIR_TOP)src/lua/
DIR_SH_SRC=$(DIR_TOP)src/shell/
DIR_RB_SRC=$(DIR_TOP)src/ruby/
DIR_TST=$(DIR_TOP)test/
GNU_TAR=gtar
include $(DIR_GEN)config.make
all:: $(DIR_GEN)config.make
# path to LUA libs, hard coded in HSTS
HSTS_LUADIR=/usr/local/share/lua/5.1/
# main script started by HSTS
MAIN_SCRIPT=validate_orchestrator.lua
# needed scripts for runtime
HSTS_SCRIPTS=$(DIR_GEN)json.lua $(DIR_GEN)config_orchestrator.lua $(DIR_LUA_SRC)forward_orchestrator.lua $(DIR_LUA_SRC)curlrest.lua $(DIR_LUA_SRC)$(MAIN_SCRIPT) $(DIR_SH_SRC)cleanup_aborted.sh
# contains generated and downloaded files
$(DIR_GEN).exists:
	mkdir -p $(DIR_GEN)
	touch $@
# generate make file macros from shell variables
$(DIR_GEN)config.make: $(DIR_GEN).exists $(DIR_PRIV)config.sh
	env -i bash -c ". $(DIR_PRIV)config.sh;set|grep '^[a-z]'" > $(DIR_GEN)config.make
# run some tests
tests: $(DIR_GEN)json.lua $(DIR_GEN)config_orchestrator.lua
	LUA_PATH="$(DIR_LUA_SRC)?.lua;$(DIR_GEN)?.lua" lua $(DIR_TST)simulator.lua $(DIR_TST)sample_session_shares_start.lua $(DIR_LUA_SRC)$(MAIN_SCRIPT)
testluacurl: $(DIR_GEN)json.lua $(DIR_GEN)config_orchestrator.lua
	LUA_PATH="$(DIR_LUA_SRC)?.lua;$(DIR_GEN)?.lua" lua -W $(DIR_TST)test_curl.lua
# download lib
$(DIR_GEN)json.lua: $(DIR_GEN).exists
	curl -so $(DIR_GEN)json.lua https://raw.githubusercontent.com/rxi/json.lua/master/json.lua
# generate configuration in json from config in shell
export orch_url orch_user orch_pass orch_workflow node_url node_user node_pass
$(DIR_GEN)config_orchestrator.lua: $(DIR_GEN).exists
	envsubst < $(DIR_LUA_SRC)config_orchestrator.tmpl.lua > $(DIR_GEN)config_orchestrator.lua
shares_download:
	ascli shares repo down /london-demo-restricted/aspera-test-dir-small/10MB.18 --transfer-info=@json:'{"wss":false}'
shares_upload:
	ascli shares repo upload 'faux:///test1?1k' --to-folder=/london-demo-restricted/Upload --transfer-info=@json:'{"wss":false}'
hsts_pack: $(HSTS_SCRIPTS)
	$(GNU_TAR) -czf $(DIR_GEN)lua.tar.gz $(HSTS_SCRIPTS) --transform 's,^.*/,,'
# deploy on test environment
hsts_deploy: $(HSTS_SCRIPTS)
	ssh $(hsts_addr) sudo bash -c "'mkdir -p $(HSTS_LUADIR);chmod a+w $(HSTS_LUADIR)'"
	scp $(HSTS_SCRIPTS) $(hsts_addr):$(HSTS_LUADIR)
	ssh $(hsts_addr) sudo bash -c "'chmod a+x $(HSTS_LUADIR)cleanup_aborted.sh'"
set_script:
	ssh $(hsts_addr) sudo asconfigurator -x "'set_user_data;user_name,$(hsts_xferuser);lua_session_start_script_path,$(HSTS_LUADIR)$(MAIN_SCRIPT)'"
remove_script:
	ssh $(hsts_addr) sudo asconfigurator -x '"set_user_data;user_name,$(hsts_xferuser);lua_session_start_script_path,AS_NULL"'
set_validation:
	ssh $(hsts_addr) sudo asconfigurator -x "'set_user_data;user_name,$(hsts_xferuser);validation_uri,$(orch_url)/external_calls/validate/$(orch_workflow);validation_session_start,uri'"
remove_validation:
	ssh $(hsts_addr) sudo asconfigurator -x '"set_user_data;user_name,$(hsts_xferuser);validation_uri,AS_NULL;validation_session_start,none"'
clean:
	rm -fr $(DIR_GEN)
