SHELL=/bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

include ../.env ../.version.env ../.gce.env
include ../.inc/common.mk
B := .build
D := ../deploy

DEN  = docker exec $(PROXY_CONTAINER_NAME)
# proxy env vars
# GH_ClIENT_ID     := $(shell cat ../../.ghClientID)
# GH_ClIENT_SECRET := $(shell cat ../../.ghClientSecret)

###########################
### NGINX CONFIGURATION ###
###########################
# ordered list of config files (without extension) referenced in nginx.conf
# the last being nginx.conf itself
ConfList   :=  tls events http redirect server nginx
buildConfs := $(patsubst %,$(B)/conf/%.conf,$(ConfList))
###########################

define mkCertsConf
# My LETSENCRYPT certs
ssl_certificate         $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/fullchain.pem;
ssl_certificate_key     $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/privkey.pem;
ssl_trusted_certificate $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/chain.pem;
endef

# local mounts
LocalMountBuild := type=bind,target=/tmp,source=$(CURDIR)/$(B)
LocalMountConf  := type=bind,target=/tmp,source=$(CURDIR)/conf
LocalMountCerts := type=bind,target=/tmp,source=$(CURDIR)/certs
LocalMountHtml  := type=bind,target=/tmp,source=$(CURDIR)/html
LocalMountGCE   := type=bind,target=/tmp,source=/home/$(GCE_NAME)/certs

dkrRunAll :=        docker run --rm --mount $(MountNginxConf) --mount $(MountLetsencrypt) --mount $(MountAssets)
dkrCpNginxConf   := docker run --rm --mount $(MountNginxConf) --mount $(LocalMountBuild)
dkrNginxConf     := docker run --rm --mount $(MountNginxConf)
dkrCpNginxHtml   := docker run --rm --mount $(MountAssets) --mount $(LocalMountHtml)
dkrTarNginxHtml  := docker run --rm --mount $(MountAssets)

.PHONY: ngx
ngx: $(D)/nginx-configuration.tar
	@$(if $(GITHUB_ACTIONS),,xdotool search --onlyvisible --name "Mozilla Firefox"  key  Control_L+F5 || true)

.PHONY: ngx-clean
ngx-clean:
	@echo '## $(@) ##'
	@rm -fv $(buildConfs) $(B)/conf/certs.conf
	@rm -fv $(D)/nginx-configuration.tar

.PHONY: restore
restore:
	@$(dkrCpNginxConf) --entrypoint "sh" $(PROXY_IMAGE) -c 'cp /tmp/conf/$(TARG) ./conf/ '

.PHONY: ls
ls:
	@$(dkrNginxConf) --entrypoint "sh" $(PROXY_IMAGE) -c 'ls -al ./conf'

.PHONY: rm
rm: 
	@$(dkrNginxConf) --entrypoint "sh" $(PROXY_IMAGE) -c 'rm ./conf/$(TARG)'

.PHONY: cat
cat: 
	@$(dkrNginxConf) --entrypoint "sh" $(PROXY_IMAGE) -c 'cat ./conf/$(TARG)'

$(D)/nginx-configuration.tar: $(B)/conf/certs.conf confs
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@#  nginx proxy configuration needs to see:
	@# 1. proxied connection so xqerl must be running
	@# 2. obtained certs are in certs location
	@echo ' - check nginx configuration'
	@$(dkrRunAll) --network $(NETWORK) --entrypoint "sh" $(PROXY_IMAGE) -c "./sbin/nginx -t"
	@echo ' - copy build files into "nginx-confguration" volume'
	@$(dkrCpNginxConf) --entrypoint "sh" $(PROXY_IMAGE) -c 'cp -r /tmp/conf ./ '
	@echo ' - tar the "nginx-confguration" volume into deploy directory'
	@$(dkrNginxConf) --entrypoint "tar" $(PROXY_IMAGE) -czf - $(PROXY_HOME)/conf > $@

$(B)/conf/certs.conf: export mkCertsConf:=$(mkCertsConf)
$(B)/conf/certs.conf:
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '## $(patsubst $(B)/%,%,$@) ##'
	@echo "$${mkCertsConf}" > $@

.PHONY: confs
confs: $(buildConfs)

define cmdTestConf
mv -v ./conf/$(*)  ./conf/hold_$(*)
cp -v /tmp/$(*) ./conf/
if ./sbin/nginx -t ; then
  rm -v ./conf/hold_$(*)
  true
else 
  mv -v  ./conf/hold_$(*) ./conf/$(*)
  false
fi
endef

$(B)/conf/%: conf/%
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '## $(*) ##'
	$(if $(GITHUB_ACTIONS),,echo ' - test configuration')
	@$(if $(GITHUB_ACTIONS),,\
 $(dkrRunAll) \
 --mount $(LocalMountConf) \
 --network $(NETWORK) \
 --entrypoint "sh" $(PROXY_IMAGE) \
 -c '$(cmdTestConf)' \
 )
	$(if $(GITHUB_ACTIONS),,echo ' -  reload nginx')
	@$(if $(GITHUB_ACTIONS),,$(DEN) ./sbin/nginx -s reload)
	@cp $< $@

.PHONY: watch
watch:
	@while true; do \
        $(MAKE) --silent confs; \
        inotifywait -qre close_write . || true; \
    done

.PHONY: index-html
index-html:
	@echo '## $@ ##'
	@#$(dkrCpNginxHtml) --entrypoint "sh" $(PROXY_IMAGE) -c 'ls /tmp/'
	@#$(dkrCpNginxHtml) --entrypoint "sh" $(PROXY_IMAGE) -c 'ls ./html'
	@$(dkrCpNginxHtml) --entrypoint "sh" $(PROXY_IMAGE) -c 'cp /tmp/* ./html/'
	@$(dkrCpNginxHtml) --entrypoint "sh" $(PROXY_IMAGE) -c 'ls ./html'
	@echo ' - tar the "nginx-confguration" volume into deploy directory'
	@$(dkrTarNginxHtml) --entrypoint "tar" $(PROXY_IMAGE) -czf - $(PROXY_HOME)/html > $@


