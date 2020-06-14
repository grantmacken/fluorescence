SHELL=/bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
include ../.env ../.version.env ../.gce.env
include ../.inc/common.mk

B := .build
D :=  ../deploy

# shotcut var expansion
Gssh := gcloud compute ssh $(GCE_NAME) --zone=$(GCE_ZONE) --project $(GCE_PROJECT_ID)
Gcmd := $(Gssh) --command
Gxq  := $(Gssh) --container $(XQ) --command
Gngx := $(Gssh) --container $(NGX) --command
Gscp := gcloud compute scp --zone=$(GCE_ZONE) --project $(GCE_PROJECT_ID) 
GceBindMountDeploy := type=bind,target=/tmp,source=/home/$(GCE_NAME)/deploy

# FUNCSgv
CopyCerts = docker cp $(NGX):$(1)/$(2).pem ./certs -L
# CopyCerts = docker cp $(NGX):$(LEpath)/$(1).pem ./certs -L

PHONY: gc-init
gc-init:
	@echo ' - on GCE login and and pull recent images'
	@$(Gcmd) \
 'echo $(ghToken) | docker login docker.pkg.github.com --username $(REPO_OWNER) --password-stdin &>/dev/null' &>/dev/null
	@$(Gcmd) 'docker pull $(XQERL_IMAGE) && docker pull $(PROXY_IMAGE)'
	@printf %60s | tr ' ' '-' && echo
	@$(Gcmd) 'docker images'
	@printf %60s | tr ' ' '-' && echo
	@$(Gcmd) 'docker ps'
	@printf %60s | tr ' ' '-' && echo

.PHONY: certs-into-vol
certs-into-vol: certs-to-host
	echo ' - bind mount the local certs dir with dummy proxy image tmp dir '
	echo ' - copy certs into letsencrypt volume'
	@docker run --rm \
 --mount $(MountLetsencrypt) \
 --mount type=bind,target=/tmp,source=$(CURDIR)/certs \
 --entrypoint "sh" $(PROXY_IMAGE) -c \
 'mkdir -p  $(LETSENCRYPT)/live/$(TLS_COMMON_NAME) \
 && mv /tmp/dh-param.pem $(LETSENCRYPT)/ \
 && cp /tmp/* $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/ \
 && rm -fv /tmp/*.pem'
	@printf %60s | tr ' ' '-' && echo

.PHONY: certs-to-host
certs-to-host:
	@echo ' - on GCE in the running ngx container copy certs into certs dir' 
	@$(Gcmd) 'mkdir -p certs \
 && $(call CopyCerts,$(LETSENCRYPT)/live/$(TLS_COMMON_NAME),cert)  \
 && $(call CopyCerts,$(LETSENCRYPT)/live/$(TLS_COMMON_NAME),fullchain)  \
 && $(call CopyCerts,$(LETSENCRYPT)/live/$(TLS_COMMON_NAME),chain)  \
 && $(call CopyCerts,$(LETSENCRYPT)/live/$(TLS_COMMON_NAME),privkey)  \
 && $(call CopyCerts,$(LETSENCRYPT),dh-param) \
 && ls -al ./certs'
	@echo ' - secure copy extracted containers certs into local certs directory' 
	@$(Gscp) $(GCE_NAME):~/certs ./ --recurse

.PHONY: certs-check
certs-check:
	@echo ' - recursive list of files on nxg server running on gcloud'
	@$(Gngx) 'ls -al $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)'
	@docker run --rm \
 --mount $(MountLetsencrypt) \
 --entrypoint "ls" $(PROXY_IMAGE) -alR  $(LETSENCRYPT)

.PHONY: certs-clean
certs-clean:
	@rm -fv $(CURDIR)/certs/*

TarList := $(wildcard $(D)/*.tar)
deployedTars := $(patsubst $(D)/%.tar,$(B)/%.txt,$(TarList))

.PHONY: gc-deploy-tars
gc-deploy-tars: $(patsubst $(D)/%.tar,$(B)/%.txt,$(TarList))

.PHONY: clean-gc-deploy-tars
clean-gc-deploy-tars: 
	@rm $(patsubst $(D)/%.tar,$(B)/%.txt,$(TarList))

gcDeploy = $(Gcmd) 'docker run --rm \
 --mount $(1) \
 --mount $(GceBindMountDeploy) \
 --entrypoint "tar" $(2) xvf /tmp/$(3).tar -C /'
gcDeploy-xqerl-database = $(call gcDeploy,$(MountData),$(XQERL_IMAGE),xqerl-database)
gcDeploy-xqerl-escripts = $(call gcDeploy,$(MountEscripts),$(XQERL_IMAGE),xqerl-escripts)
gcDeploy-xqerl-compiled-code = $(call gcDeploy,$(MountCode),$(XQERL_IMAGE),xqerl-compiled-code)
gcDeploy-static-assets = $(call gcDeploy,$(MountAssets),$(PROXY_IMAGE),static-assets)
gcDeploy-nginx-configuration = $(call gcDeploy,$(MountNginxConf),$(PROXY_IMAGE),nginx-configuration)

$(B)/%.txt: $(T)/%.txt
	@mkdir -p $(dir $@)
	@echo '## $@ ##'
	@$(call gcDeploy-$(shell grep -oP 'deploy/\K([a-z-]+)' $<)) > $@

$(T)/%.txt: $(D)/%.tar
	@mkdir -p $(dir $@)
	@$(Gscp) $(abspath $<) $(GCE_NAME):~/deploy/ &>/dev/null
	@$(Gcmd) 'ls -al $(patsubst $(D)/%,deploy/%,$(<))' > $@

.PHONY: gc-xq-up
gc-xq-up:
	@$(Gcmd) '$(xqRun)'

.PHONY: gc-xq-stop
gc-xq-stop:
	@$(Gcmd) 'docker stop xq'

.PHONY: gc-code
gc-code:
	@$(Gxq) 'xqerl eval "$(xqOrderedCompile)"'

.PHONY: gc-ngx-up
gc-ngx-up:
	@$(Gcmd) '$(ngxRun)'

.PHONY: gc-ngx-restart
gc-ngx-restart:
	@echo "## $@ ##"
	@echo ' - remote test nginx configuration'
	@$(Gcmd) 'docker exec $(PROXY_CONTAINER_NAME) ./sbin/nginx -t'
	@echo ' - remote restart'
	@$(Gcmd) 'docker exec $(PROXY_CONTAINER_NAME) ./sbin/nginx -s reload'

.PHONY: gc-init-dirs
gc-init-dirs:
	@echo "## $@ ##"
	@echo ' - once off, set up stuff'
	@echo 'set up dir structure on static-assets volume ... '
	@$(Gcmd) 'docker run --rm --mount $(MountAssets) --entrypoint "sh" $(PROXY_IMAGE) \
 -c "\
 mkdir -p  html/$(DOMAIN)/static-assets/fonts && \
 mkdir -p  html/$(DOMAIN)/static-assets/icons && \
 mkdir -p  html/$(DOMAIN)/static-assets/images && \
 mkdir -p  html/$(DOMAIN)/static-assets/scripts && \
 mkdir -p html/$(DOMAIN)/static-assets/styles"'
	@$(Gcmd) 'docker run --rm --mount $(MountAssets) --entrypoint "sh" $(PROXY_IMAGE) \
 -c "ls -R html/$(DOMAIN)"'
