
EscriptList       := $(wildcard bin/*.escript)
EscriptBuildList  := $(patsubst bin/%,$(B)/bin/scripts/%,$(EscriptList))

.PHONY: escript
escript:  $(D)/xqerl-escripts.tar

.PHONY: clean-escript
clean-escript:
	@rm -v $(D)/xqerl-escripts.tar
	@rm -v $(EscriptBuildList)


$(D)/xqerl-escripts.tar: $(EscriptBuildList)
		@docker run --rm \
 --mount $(MountEscripts) \
 --entrypoint "tar" $(XQERL_IMAGE) -czf - $(XQERL_HOME)/bin/scripts &>/dev/null > $@
	$(call Tick, '- [ $(basename $(notdir $@)) ] tarred ')
	@echo;printf %60s | tr ' ' '-' && echo


$(B)/bin/scripts/%: bin/%
	@mkdir -p $(dir $@)
	@cp $< $@
	@docker run --rm \
 --mount $(MountEscripts) \
 --mount $(BindMountBuild) \
 --entrypoint "sh" $(XQERL_IMAGE) -c 'cp -v /tmp/$(patsubst $(B)/%,%,$@) $(dir $(patsubst $(B)/%,%,$@))'
	@echo;printf %60s | tr ' ' '-' && echo
	@#docker cp $(<) $(XQ):$(XQERL_HOME)/bin/scripts/

