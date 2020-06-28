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
ctXML :=  --header "Content-Type: application/xml"
ACCEPT_JSON :=  --header "Accept: application/json"
SEND  := --data-binary @-
WRITE := --write-out $(WriteOut)
COMMENT_OPEN := <!--
BASE_URL  := http://$(XQ)/$(DOMAIN)
POSTS_URL :=  $(BASE_URL)/_posts

# calls
extractFM = sed -n '/^<!--/,/^-->/p;/^-->/q' $1 | sed -n '/^<!--/,/^-->/{//!p}'
postStatus  = $(shell $(call extractFM,$1) | \
              jq -e '."post-status"')
postUid  = $(shell $(call extractFM,$1) | \
              jq -e '."uid"')

# content is built locally

.PHONY: publish
publish: $(D)/xqerl-database.tar

.PHONY: clean-publish
clean-publish:
	@echo '## $@ ##'
	@#rm -fv $(wildcard $(B)/publish/*)
	@rm -f $(D)/xqerl-database.tar

$(D)/xqerl-database.tar: $(PublishBuildList)
	@# echo '## $(notdir $@) ##'
	@docker run --rm \
 --mount $(MountData) \
 --entrypoint "tar" $(XQERL_IMAGE) -czf - $(XQERL_HOME)/data &>/dev/null > $@

.PHONY: db-tar-deploy
db-tar-deploy:
	cat $(D)/xqerl-database.tar |
	docker run --rm --mount $(MountData) \
 --entrypoint "tar" $(XQERL_IMAGE) - xvf /tmp/xqerl-database.tar -C /

$(B)/publish/%.json: $(T)/publish/%.xml
	echo '##[ $< ]##'
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	if [[ $(call postStatus,$(patsubst $(T)/%.xml,%.md,$<)) == 'updated' ]]; then touch $@; fi
	if [[ $(call postStatus,$(patsubst $(T)/%.xml,%.md,$<)) == 'created' ]]; then touch $@; fi
	if [[ $(call postStatus,$(patsubst $(T)/%.xml,%.md,$<)) == 'update' ]]; then
	# local post
	cat $< |
	  $(CURL) -s $(ctXML) $(SEND) -X PUT $(call postUid,$(patsubst $(T)/%.xml,%.md,$<)) |
	  jq -e '.' > $(basename $<).json
	echo '-------------------'
	jq -e '.' $(basename $<).json
	# gcloud post
	$(Gscp) $< $(GCE_NAME):~/publish/ &>/dev/null
	#$(Gcmd) 'echo $(call postUid,$(patsubst $(T)/%.xml,%.md,$<))'
	$(Gcmd) 'cat $(patsubst $(T)/%,%,$<) | \
 $(CURL) -s $(ctXML) $(SEND) -X PUT $(call postUid,$(patsubst $(T)/%.xml,%.md,$<))'  &>/dev/null
	@mv $(basename $<).json $@
	sed -i 's/"update"/"updated"/' $(patsubst $(T)/%.xml,%.md,$<)
	xdotool search --onlyvisible --name "Mozilla Firefox"  key  Control_L+F5 || true
	fi
	if [[ $(call postStatus,$(patsubst $(T)/%.xml,%.md,$<)) == 'create' ]]; then 
	cat $< | $(CURL) -s $(ctXML) $(SEND) $(POSTS_URL) |
	jq -e '.' > $(basename $<).json
	# gcloud: send XML to host
	$(Gscp) $< $(GCE_NAME):~/publish/ &>/dev/null
	#$(Gcmd) 'echo $(call postUid,$(patsubst $(T)/%.xml,%.md,$<))'
	$(Gcmd) 'cat $(patsubst $(T)/%,%,$<) | \
 $(CURL) -s $(ctXML) $(SEND) $(POSTS_URL)'  &>/dev/null
	# create tmp file
	# copy post result into front matter
	echo '' > $(basename $<).md
	echo '<!--' >> $(basename $<).md
	jq -e '.' $(basename $<).json >> $(basename $<).md
	echo '-->' >> $(basename $<).md
	# extract exiting markdown after frontmatter
	sed -ne '/^-->/,$${//!p}' $(patsubst $(T)/%.xml,%.md,$<) >> $(basename $<).md
	# overwrite src md document
	mv -f $(basename $<).md $(patsubst $(T)/%.xml,%.md,$<)
	# mv document recieved from post to target
	@mv $(basename $<).json $@
	fi


xcdffffffff:
	# create tmp file
	# copy post result into front matter
	echo '<!--' > $(basename $<).md
	jq -e '.' $@ >> $(basename $<).md
	echo '-->' >> $(basename $<).md
	# extract exiting markdown after frontmatter
	sed -ne '/^-->/,$${//!p}' $(patsubst $(T)/%.xml,%.md,$<) >> $(basename $<).md
	# overwrite src md document
	mv -f $(basename $<).md $(patsubst $(T)/%.xml,%.md,$<)
	# mv document recieved from post to target
	@mv $(basename $<).json $@
	fi

$(T)/publish/%.xml: publish/%.md
	echo '##[ $< ]##'
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	# this is the quickfix errformat for vim
	echo "$<:1: post status - $(call postStatus,$<)"
	if [[ $(call postStatus,$<) == 'updated' ]]; then touch $@; fi
	if [[ $(call postStatus,$<) == 'created' ]]; then touch $@; fi
	if [[ $(call postStatus,$<) == 'update' ]]; then 
	cat $< | $(CMARK) > $@
	fi
	if [[ $(call postStatus,$<) == 'create' ]]; then 
	cat $< | $(CMARK) > $@
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

slug = $$(echo "publish/$$(date --iso)-$1" | sed 's/ /-/g').md

.PHONY: new-article
new-article:
	@echo 'type name for page, then hit enter'
	@read line
	if [[ $$line == '' ]]
	then 
	echo 'aborting ... MUST add name for page'
	exit 1
	fi
	echo "creating a new article[  $(call slug,$$line) ]"
	echo '<!--' >  $(call slug,$$line)
	echo "{ \"post-status\" : \"draft\"$(COMMA)\"slug\" : \"$$line\" }" |
	jq -e '.' >>  $(call slug,$$line)
	echo '-->'>>  $(call slug,$$line)
	cat <<EOF | tee -a $(call slug,$$line)
	In the frontmatter, you can
	 * change the 'slug' value to create a page name.
	 * change the 'post-status' value to 'create' when you are ready to publish
	EOF

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
