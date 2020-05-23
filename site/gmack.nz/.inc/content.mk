#############
### POSTS ###
#############
ifeq ($(origin TITLE),undefined)
 TITLE := $(EMPTY)
endif
ifeq ($(origin INDEX),undefined)
 INDEX := $(EMPTY)
endif

BindMountDeploy  := type=bind,target=/tmp,source=$(abspath ../../deploy)
BuildContentList := $(patsubst %.md,$(B)/%.json,$(wildcard content/*.md))

.PHONY: content
content: $(D)/xqerl-database.tar

$(D)/xqerl-database.tar: $(BuildContentList)
	@# echo '## $(notdir $@) ##'
	@docker run --rm \
 --mount $(MountData) \
 --entrypoint "tar" $(XQERL_IMAGE) -czf - $(XQERL_HOME)/data &>/dev/null > $@
	@#echo;printf %60s | tr ' ' '-' && echo
#$(P)/home/index.txt

.PHONY: db-tar-deploy
db-tar-deploy:
	docker run --rm \
 --mount $(MountData) \
 --mount $(BindMountDeploy) \
 --entrypoint "tar" $(XQERL_IMAGE) xvf /tmp/xqerl-database.tar -C /

.PHONY: clean-content
clean-content:
	@echo '## $@ ##'
	@rm -fv $(wildcard $(B)/content/*/*)
	@rm -fv $(wildcard $(T)/content/*/*)
	@rm -f $(D)/xqerl-database.tar

xxxx/content/%.html:
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@#check point:  jq with error in not valid json
	@cat $(dir $<)output-$(notdir $<) | jq '.' &>/dev/null
	@#TODO! check some headers 
	@cat $(dir $<)headers-$(notdir $<)
	@$(call locationGET,$(call locationHeader,$(dir $<)headers-$(notdir $<))) |
	tidy -i -q  \
 --indent yes \
 --punctuation-wrap yes \
 --indent-attributes yes \
 --wrap 0 \
 --warn-proprietary-attributes no \
 --tidy-mark no | 
	tee $@ 

$(B)/content/%.json:  $(T)/content/%.xml
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@#echo "##[ $(notdir $@) ]##"
	@sed -e '1,2d' $< | $(call xmlPOST,/_posts,$@) | tee $(dir $@)$(basename $(notdir $@)).writeout
	@echo
	cat $@ | jq '.' 
	@#TODO! check some headers 
	@cat $(dir $@)$(basename $(notdir $@)).header

$(T)/content/%.xml: content/%.md
	@mkdir -p $(dir $@)
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@#echo "##[ $(notdir $@) ]##"
	@cmark --to xml $< > $@



#########################################
slug != echo "content/$(shell date --iso)-$(shell echo $(TITLE) | sed 's/ /-/g').md"

.PHONY: new-index-page
new-index-page:
	@$(if $(INDEX),, echo "usage: make INDEX='home':  you need to add INDEX" && false)
	@mkdir -p content/$(INDEX)
	@$(file > content/$(INDEX)/index.md,<!--{)
	@$(file >> content/$(INDEX)/index.md,"title" : "My Index Page"$(COMMA))
	@$(file >> content/$(INDEX)/index.md,"collection" : "$(INDEX)"$(COMMA))
	@$(file >> content/$(INDEX)/index.md,"index" : "yep")
	@$(file >> content/$(INDEX)/index.md,}-->)
	@$(file >> content/$(INDEX)/index.md,)
	@$(file >> content/$(INDEX)/index.md,My first sentence.)

.PHONY: new-page
new-page:
	@$(if $(TITLE),, echo "usage: make TITLE='my title':  you need to add TITLE" && false)
	@mkdir -p articles
	@$(file > $(slug),<!--{)
	@$(file >> $(slug),"title" : "$(TITLE)")
	@$(file >> $(slug),}-->)
	@$(file >> $(slug),# $(TITLE))
	@$(file >> $(slug),)
	@$(file >> $(slug),My first sentence.)

