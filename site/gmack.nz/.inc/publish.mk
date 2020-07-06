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
OUT_HEADER := --output /dev/null --dump-header -
WRITE := --write-out $(WriteOut)
COMMENT_OPEN := <!--
BASE_URL  := http://$(XQ)/$(DOMAIN)
POSTS_URL :=  $(BASE_URL)/_posts

# calls
#
extractFM = sed -n '/^<!--/,/^-->/p;/^-->/q' $1  | sed -n '/^<!--/,/^-->/{//!p}'
pubStatus  = $(shell $(call extractFM,$1) | \
              jq -e '."status"')
pubUid  = $(shell $(call extractFM,$1) | \
              jq -e '."uid"')

# header file
extractHeader = $(shell grep -oP  '^$2: \K(.+)$$' $1)
extractStatus = $(shell grep -oP  '^HTTP/1.1 \K(.+)$$' $1)
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

$(B)/publish/%.json: $(T)/publish/%.header
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	case $(call pubStatus,publish/$(*).md) in
	'update')
	  echo '## [ gcloud update ]##'
	  $(Gscp) $(basename $<).xml $(GCE_NAME):~/publish/ &>/dev/null
	  $(Gcmd) 'cat ~/publish/$(*).xml |
		$(CURL) -s $(ctXML) $(SEND) -X PUT $(call pubUid,publish/$(*).md)' |
	  jq -e '.' |
	  tee $@
	  echo "$$(awk '/"status": [^"]*"[^"]*"/ && !done \
    { gsub ( /update/,"updated"); done=1;}; 1;' \
    publish/$(*).md )" > publish/$(*).md
	  ;;
	'create')
	  echo '## [ gcloud create ]##'
	  $(Gscp) $(basename $<).xml $(GCE_NAME):~/publish/ &>/dev/null
	  $(Gcmd) 'cat publish/$(*).xml | $(CURL) -s $(ctXML) $(SEND) $(POSTS_URL)' |
	  jq -e '.' |
	  tee $@
	  echo "$$(awk '/"status": [^"]*"[^"]*"/ && !done { \
    gsub ( /create/,"created"); done=1;}; 1;' publish/$(*).md | \
    awk '/"slug": [^"]*"[^"]*"/ && !done { \
    gsub (/"slug": [^"]*"[^"]*"/,\
    "\"uid\": \"$(call extractHeader,$<,location)\"");\
    done=1;};1;')" > publish/$(*).md
	  ;;
	 *)
	  touch $@
	  ;;
	esac

$(T)/publish/%.header: $(T)/publish/%.xml
	echo '##[ $< ]##'
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	case $(call pubStatus,publish/$(*).md) in
	 'update')
	  echo '## [ local update ]##'
	  cat $< | $(CURL) -s $(ctXML) $(SEND) $(OUT_HEADER) -X PUT $(call pubUid,publish/$(*).md) > $@
	  xdotool search --onlyvisible --name "Mozilla Firefox"  key  Control_L+F5 || true
	  ;;
	 'create')
	  echo '## [ local create ]##'
	  cat $< | $(CURL) -s $(ctXML) $(SEND) $(OUT_HEADER) $(POSTS_URL) | tee $@
	  xdotool search --onlyvisible --name "Mozilla Firefox"  key  Control_L+F5 || true
	  ;;
	 *)
	  touch $@
	  ;;
	esac

$(T)/publish/%.xml: publish/%.md
	echo '##[ $< ]##'
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	if [ -z "$$(sed -n '/^<!--/,/^-->/p;/^-->/q' $<)" ]
	then 
	  echo 'ERROR: rontmatter block: check formating '
	  echo ' - frontmatter should open and close with HTML comment'
	  echo ' - frontmatter should contain well formed JSON object'
	  false
	fi
	sed -n '/^<!--/,/^-->/p;/^-->/q' $<  | sed -n '/^<!--/,/^-->/{//!p}' |
	jq -e '.' > $(basename $@).json
	# this is the quickfix errformat for vim
	echo "$<:1: post status - $(call pubStatus,$<)"
	case $(call pubStatus,$<) in
	 'update')
	  cat $< | $(CMARK) > $@
	  ;;
	 'create')
	  cat $< | $(CMARK) > $@
	  ;;
	 'fetch')
	  echo '## [ local fetch ]##'
		# recreate frontmatter
		echo '<!--' > $(basename $@).md
	  cat $< | $(CURL) -s $(ACCEPT_JSON) $(call pubUid,$<) |
		jq -e '.' |
	  jq '.status = "fetched"' >> $(basename $@).md
	  echo '-->' >> $(basename $@).md
	  # extract markdown body
	  sed -ne '/^-->/,$${//!p}' $< >> $(basename $@).md
		mv $(basename $@).md $<
	  ;;
	 *)
	  touch $@
	  ;;
	esac

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
