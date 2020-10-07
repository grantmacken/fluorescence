
EscriptList       := $(wildcard bin/*.escript)
EscriptBuildList  := $(patsubst bin/%,$(B)/bin/scripts/%,$(EscriptList))

.PHONY: escript
escript:  $(D)/xqerl-escripts.tar

.PHONY: clean-escript
clean-escript:
	@rm -vf $(D)/xqerl-escripts.tar
	@rm -vf $(EscriptBuildList)

$(D)/xqerl-escripts.tar: $(EscriptBuildList)
		@docker run --rm \
 --mount $(MountEscripts) \
 --entrypoint "tar" $(XQERL_IMAGE) -czf - $(XQERL_HOME)/bin/scripts &>/dev/null > $@
	$(call Tick, '- [ $(basename $(notdir $@)) ] tarred ')
	@echo;printf %60s | tr ' ' '-' && echo


$(B)/bin/scripts/%: bin/%
	@mkdir -p $(dir $@)
	@#echo '##[ $* ]##'
	@cat $< | \
 docker run --rm --interactive --mount $(MountEscripts) --entrypoint "sh" $(XQERL_IMAGE) \
 -c 'cat - > $(patsubst $(B)/%,%,$@) && cat $(patsubst $(B)/%,%,$@)' > $@
