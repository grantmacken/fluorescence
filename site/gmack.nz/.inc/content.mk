#############
### POSTS ###
#############
ifeq ($(origin TITLE),undefined)
 TITLE := $(EMPTY)
endif

BuildContentList := $(patsubst %.md,$(B)/%.json,$(wildcard content/*/*.md))

.PHONY: content
content: $(D)/xqerl-database.tar

$(D)/xqerl-database.tar: $(BuildContentList)
	@# echo '## $(notdir $@) ##'
	@docker run --rm \
 --mount $(MountData) \
 --entrypoint "tar" $(XQERL_DOCKER_IMAGE) -czf - $(XQERL_HOME)/data &>/dev/null > $@
	@#echo;printf %60s | tr ' ' '-' && echo
#$(P)/home/index.txt

.PHONY: clean-content
clean-content:
	@echo '## $@ ##'
	@rm -fv $(wildcard $(B)/content/*/*)
	@rm -fv $(wildcard $(T)/content/*/*)
	@rm -f $(D)/xqerl-database.tar

slug != echo "content/articles/$(shell date --iso)-$(shell echo $(TITLE) | sed 's/ /-/g').md"

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

.PHONY: new-home-page
new-home-page:
	@$(file > content/index.md,<!--{)
	@$(file >> content/index.md,"title" : "My Home Page"$(COMMA))
	@$(file >> content/index.md,"collection" : "home"$(COMMA))
	@$(file >> content/index.md,"index" : "yep")
	@$(file >> content/index.md,}-->)
	@$(file >> content/index.md,# My Home Page Title )
	@$(file >> content/index.md,)
	@$(file >> content/index.md,My first sentence.)

.PHONY: new-article
new-article:
	@$(if $(TITLE),, echo "usage: make TITLE='my title':  you need to add TITLE" && false)
	@mkdir -p articles
	@$(file > $(slug),<!--{)
	@$(file >> $(slug),"title" : "$(TITLE)")
	@$(file >> $(slug),}-->)
	@$(file >> $(slug),# $(TITLE))
	@$(file >> $(slug),)
	@$(file >> $(slug),My first sentence.)

