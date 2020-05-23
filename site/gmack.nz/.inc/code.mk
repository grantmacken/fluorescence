# NOTE: call root is site directory ../
#
#  NOTE: xquery module list order is important
#   req_res render posts login routes
ModuleList := newBase60 maps req_res render posts routes
# render_feed render_note micropub routes
CodeBuildList  := $(patsubst %,$(B)/code/%.xqm,$(ModuleList))
# CALLS
compile =  $(ESCRIPT) bin/scripts/compile.escript ./code/src/$1

PHONY: code
code: $(D)/xqerl-compiled-code.tar

PHONY: clean-code
clean-code:
	@echo '## $@ ##'
	@rm -fv $(D)/xqerl-compiled-code.tar
	@rm -fv $(B)/code/*
	@rm -fv $(T)/compile_result/*
	@rm -fv $(T)/check_route/*

$(D)/xqerl-compiled-code.tar: $(CodeBuildList)
	@mkdir -p $(dir $@)
	@# $(MAKE) check-routes
	@docker run --rm \
 --mount $(MountCode) \
 --entrypoint "tar" $(XQERL_IMAGE) -czf - $(XQERL_HOME)/code &>/dev/null > $@
	$(call Tick, '- [ $(basename $(notdir $@)) ] tarred ')
	@echo;printf %60s | tr ' ' '-' && echo

# $(T)/compile_result/%.txt 

$(B)/code/%.xqm: $(T)/compile_result/%.txt
	@mkdir -p $(dir $@)
	@$(call GrepOK,':I:',$<) || ( cat $< && echo )
	@$(call IsOK,':I:',$<,compiled)
	@#docker cp $(XQ):$(XQERL_HOME)/code/src/$(notdir $@) $(dir $@)
	@#$(DEX) ls -al $(XQERL_HOME)/code/src/$(notdir $@)
	@$(DEX) cat $(XQERL_HOME)/code/src/$(notdir $@) > $@
	@$(DEX) rm $(XQERL_HOME)/code/src/$(notdir $@)

# .PRECIOUS: $(C)/code/%.txt
$(T)/compile_result/%.txt: code/%.xqm
	@mkdir -p $(dir $@)
	@docker cp $(<) $(XQ):$(XQERL_HOME)/code/src
	@$(call compile,$(notdir $<)) > $@
	@#check: xqerl can compile
	@# check: routes do not return 500 status
	@# $(MAKE) -silent routes 

.PHONY: check-xq-routes
check-xq-routes: home-page

.PHONY: check-xq-routes-more
check-xq-routes-more: home-page-more

.PHONY: clean-routes
clean-routes:
	@rm -f $(T)/check_route/*

.PHONY: home-page
home-page: $(T)/check_route/home-page
	@mkdir -p $(dir $@)
	@echo 'check route [ $@ ]'
	@$(call ServesHeader,$(dir $<)/headers-$(notdir $<),HTTP/1.1 200, - status OK!)
	@$(call HasHeaderKeyShowValue,$(dir $<)/headers-$(notdir $<),content-type)

.PHONY: home-page-more
home-page-more: $(T)/check_route/home-page
	@mkdir -p $(dir $@)
	@echo 'check route [ $@ ]'
	@echo;printf %60s | tr ' ' '-' && echo
	@cat $<
	@echo;printf %60s | tr ' ' '-' && echo
	@cat $(dir $<)/headers-$(notdir $<)
	@echo;printf %60s | tr ' ' '-' && echo
	@cat $(dir $<)/doc-$(notdir $<)
	@echo;printf %60s | tr ' ' '-' && echo
	@$(call ServesHeader,$(dir $<)/headers-$(notdir $<),HTTP/1.1 200, - status OK!)
	@$(call HasHeaderKeyShowValue,$(dir $<)/headers-$(notdir $<),content-type)

$(T)/check_route/home-page:
	@mkdir -p $(dir $@)
	@$(call GET,/,$@)
