# NOTE: call root is site directory ../
#
#  NOTE: xquery module list order is important
#   req_res render posts login routes
ModuleList := newBase60 maps req_res render posts routes
# render_feed render_note micropub routes
CodeBuildList  := $(patsubst %,$(B)/code/src/%.xqm,$(ModuleList))

compiledLibs := 'BinList = xqerl_code_server:library_namespaces(),\
 NormalList = [binary_to_list(X) || X <- BinList],\
 io:fwrite("~1p~n",[lists:sort(NormalList)]).'
#  EXPANSIONS
DEX := docker exec $(XQ)
EVAL := $(DEX) xqerl eval
ESCRIPT := $(DEX) xqerl escript
# CALLS
compile =  $(ESCRIPT) bin/scripts/compile.escript ./code/src/$1

PHONY: code
code: $(D)/xqerl-compiled-code.tar

PHONY: recompile
recompile: 
	@$(ESCRIPT) bin/scripts/compile.escript ./code/src/newBase60.xqm

PHONY: clean-code
clean-code:
	@echo '## $@ ##'
	@rm -fv $(D)/xqerl-compiled-code.tar
	@rm -fv $(B)/code/*
	@rm -fv $(T)/compile_result/*

$(D)/xqerl-compiled-code.tar: $(CodeBuildList)
	@mkdir -p $(dir $@)
	@# $(MAKE) check-routes
	@docker run --rm \
 --mount $(MountCode) \
 --entrypoint "tar" $(XQERL_IMAGE) -czf - $(XQERL_HOME)/code &>/dev/null > $@
	$(call Tick, '- [ $(basename $(notdir $@)) ] tarred ')
	@echo;printf %60s | tr ' ' '-' && echo

$(B)/code/src/%.xqm: code/%.xqm
	@mkdir -p $(dir $@)
	@#echo '##[ $< ]##'
	@#NOTE: docker copy set permissions as USER whereas cat method results in root user 
	@docker cp $(<) $(XQ):$(XQERL_HOME)/$(dir $(patsubst $(B)/%,%,$@))
	@$(call compile,$(notdir $<)) > $(T)/compile_result/$*.txt
	@$(call GrepOK,':I:',$(T)/compile_result/$*.txt) || ( cat $(T)/compile_result/$*.txt && echo )
	@$(call IsOK,':I:',$(T)/compile_result/$*.txt,compiled)
	@cp $< $@


