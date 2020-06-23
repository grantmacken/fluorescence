#############
### POSTS ###
#############
ifeq ($(origin SLUG),undefined)
 SLUG := $(EMPTY)
endif
ifeq ($(origin PUBLISH),undefined)
 PUBLISH := $(EMPTY)
endif
ifeq ($(origin INDEX),undefined)
 INDEX := $(EMPTY)
endif

BindMountDeploy  := type=bind,target=/tmp,source=$(abspath ../../deploy)

PublishList := $(wildcard publish/*.md)
PublishBuildList   := $(patsubst %.md,$(B)/%.json,$(PublishList))

CMARK_IMAGE := docker.pkg.github.com/$(REPO_OWNER)/alpine-cmark/cmark:$(CMARK_VER)

CMARK := docker run --rm  --interactive $(CMARK_IMAGE) --to xml | sed -e '1,2d'
ctXML :=  --header 'Content-Type: application/xml'
ACCEPT_JSON :=  --header 'Accept: application/json'
SEND  := --data-binary @-
WRITE := --write-out $(WriteOut)
COMMENT_OPEN := <!--
BASE_URL  := http://$(XQ)/$(DOMAIN)
POSTS_URL :=  $(BASE_URL)/_posts

# content is built locally

.PHONY: publish
publish: $(D)/xqerl-database.tar
	@xdotool search --onlyvisible --name "Mozilla Firefox"  key  Control_L+F5 || true

.PHONY: clean-publish
clean-publish:
	@echo '## $@ ##'
	@# do not use rm -frv $(wildcard publish/$(P)/*)
	@rm -fv $(wildcard $(B)/publish/*)
	@rm -f $(D)/xqerl-database.tar

$(D)/xqerl-database.tar: $(PublishBuildList)
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

extractFM = sed -n '/^<!--/,/^-->/p;/^-->/q' $1 | sed -n '/^<!--/,/^-->/{//!p}'
postStatus  = $(shell $(call extractFM,$1) | \
              jq -e '."post-status"')
postUid  = $(shell $(call extractFM,$1) | \
              jq -e '."uid"')

$(B)/publish/%.json: publish/%.md
	echo '##[ $< ]##'
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	# this is the quickfix errformat for vim
	echo "$<:1: post status - $(call postStatus,$<)"
	if [[ $(call postStatus,$<) == 'updated' ]]; then touch $@; fi
	if [[ $(call postStatus,$<) == 'created' ]]; then touch $@; fi
	if [[ $(call postStatus,$<) == 'update' ]]; then 
	cat $< |
	  $(CMARK) |
	  $(CURL) -s $(ctXML) $(SEND) -X PUT $(call postUid,$<) |
	  jq -e '.' > $@
	jq -e '.' $@
	sed -i 's/"update"/"updated"/' $<
	fi
	if [[ $(call postStatus,$<) == 'create' ]]; then 
	cat $< |
	  $(CMARK) |
	  $(CURL) -s $(ctXML) $(SEND) $(POSTS_URL) |
	  jq -e '.'  >  $@
	jq -e '.' $@
	echo '<!--' > $@.md
	jq -e '.' $@ >> $@.md
	echo '-->' >> $@.md
	sed -ne '/^-->/,$${//!p}' $< >> $@.md
	mv -f $@.md $<
	fi

#########################################

.PHONY: ct
ct:
	@echo '##[ $@ ]##'
	@$(MAKE) new-index-page INDEX=home


.PHONY: new-index-page
new-index-page:
	@$(if $(INDEX),, echo "usage: make INDEX='home':  you need to add INDEX" && false)
	@$(file > publish/$(INDEX)-index.md,<!--)
	@$(file >> publish/$(INDEX)-index.md,{)
	@$(file >> publish/$(INDEX)-index.md,  "post-status" : "draft"$(COMMA))
	@$(file >> publish/$(INDEX)-index.md,  "collection" : "$(INDEX)"$(COMMA))
	@$(file >> publish/$(INDEX)-index.md,  "index" : "yep")
	@$(file >> publish/$(INDEX)-index.md,})
	@$(file >> publish/$(INDEX)-index.md,-->)
	@$(file >> publish/$(INDEX)-index.md,)
	@$(file >> publish/$(INDEX)-index.md,My $(INDEX) page sentence)

slug != echo "publish/$(shell date --iso)-$(shell echo $(SLUG) | sed 's/ /-/g').md"

.PHONY: new-article
new-article:
	@$(if $(SLUG),, echo "usage: make new-article SLUG='my page name'" && false)
	@$(file > $(slug),<!--)
	@$(file >> $(slug),{)
	@$(file >> $(slug),  "post-status" : "draft"$(COMMA))
	@$(file >> $(slug),  "slug" : "$(SLUG)")
	@$(file >> $(slug),})
	@$(file >> $(slug),-->)
	@$(file >> $(slug),)
	@$(file >> $(slug),My interesting sentence)

Gssh := gcloud compute ssh $(GCE_NAME) --zone=$(GCE_ZONE) --project $(GCE_PROJECT_ID)
Gcmd := $(Gssh) --command

.PHONY: crl-get
crl-get:
	@echo '### $@ ###'
	@# $(CURL) -s http://xq/gmack.nz/home/index
	@$(CURL) -s http://xq/gmack.nz/article/index
	@#$(CURL) -s http://xq/gmack.nz/xxx/ddd
	@$(Gcmd) '$(CURL) -v http://xq/gmack.nz/article/xxx'
	@echo

.PHONY: crl-get-json
crl-get-json:
	@echo '### $@ ###'
	@$(CURL) -H 'Accept: application/json'  -s http://xq/gmack.nz/article/name-resolution-on-a-docker-network |
	jq '.'
	@echo

.PHONY: crl-put-xml
crl-put-xml:
	@echo '### $@ ###'
	cat  publish/home-index.md |
	$(CMARK) | $(CURL) -v $(ctXML) $(SEND) -X PUT http://xq/gmack.nz/article/index
	@echo
