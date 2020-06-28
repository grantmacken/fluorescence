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

gcTarList := xqerl-compiled-code xqerl-escripts static-assets nginx-configuration
gcDeployTars := $(patsubst %,$(B)/deploy/%.tar,$(gcTarList))
gcCopyCerts = docker cp $(NGX):$(1)/$(2).pem ./certs -L

.PHONY: gc-deploy-tars
gc-deploy-tars: $(gcDeployTars)

.PHONY: gc-clean
gc-clean:
	@echo '## $@) ##'
	@rm -fv $(B)/deploy/*
	@rm -fv $(T)/deploy/*

$(B)/xdeploy/%.txt: $(T)/xdeploy/%.toc
	@mkdir -p $(dir $@)
	@echo '## $@ ##'
	echo '$(basename $<)'
	echo '$(*)'
	@cat $(D)/$(*).tar | tar zft - > $(basename $<).txt
	if cmp --print-bytes $< $(basename $<).txt &>/dev/null
	then
	echo 'good'
	else
	echo ''
	fi

$(B)/deploy/%.tar: $(D)/%.tar
	echo '## $(*) ##'
	mkdir -p $(dir $@)
	echo 'copy $* tar onto GCE host'
	$(Gscp) $(abspath $<) $(GCE_NAME):~/deploy/ &>/dev/null
	$(Gcmd) 'ls -al $(patsubst $(D)/%,deploy/%,$(<))' 
	$(call gcDeploy-$(*))
	if [[ '$*' == 'xqerl-compiled-code' ]] 
	then
	$(Gxq) 'xqerl eval "$(xqOrderedCompile)"'
	fi
	if [[ '$*' == 'nginx-configuration' ]] 
	then
	echo ' - remote test nginx configuration'
	$(Gcmd) 'docker exec $(PROXY_CONTAINER_NAME) ./sbin/nginx -t'
	echo ' - remote restart'
	$(Gcmd) 'docker exec $(PROXY_CONTAINER_NAME) ./sbin/nginx -s reload'
	fi
	@# cat $(T)/deploy/$(notdir $<) | tar zft - > $@
	@cp $< $@


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

.PHONY: gc-ngx-stop
gc-ngx-stop:
	@$(Gcmd) 'docker stop ngx'

.PHONY: gc-ngx-restart
gc-ngx-restart:
	@echo "## $@ ##"
	@echo ' - remote test nginx configuration'
	@$(Gcmd) 'docker exec $(PROXY_CONTAINER_NAME) ./sbin/nginx -t'
	@echo ' - remote restart'
	@$(Gcmd) 'docker exec $(PROXY_CONTAINER_NAME) ./sbin/nginx -s reload'

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

.PHONY: gc-once
gc-once:
	@echo "## $@ ##"
	@echo ' - once off, set up stuff'
	@echo 'set up letsencrypt volume'
	@$(Gcmd) 'docker volume list | grep -q "letsencrypt" || docker volume create letsencypt'
	@echo 'set up dir structure on static-assets volume ... '
	$(Gcmd) 'docker network create $(NETWORK)'
	@$(Gcmd) 'docker run --rm --mount $(MountAssets) --entrypoint "sh" $(PROXY_IMAGE) \
 -c "\
 mkdir -p  html/$(DOMAIN)/static-assets/fonts && \
 mkdir -p  html/$(DOMAIN)/static-assets/icons && \
 mkdir -p  html/$(DOMAIN)/static-assets/images && \
 mkdir -p  html/$(DOMAIN)/static-assets/scripts && \
 mkdir -p html/$(DOMAIN)/static-assets/styles"'
	@$(Gcmd) 'docker run --rm --mount $(MountAssets) --entrypoint "sh" $(PROXY_IMAGE) \
 -c "ls -R html/$(DOMAIN)"'

##############################
## CERTBOT section
## prefix cb
##############################

cb-clean:
	@echo '## $@ ##'
	@rm -f $(B)/cli.ini

cb-ini: $(B)/cli.ini

define certbotConfig
rsa-key-size = 2048
email = $(GIT_EMAIL)
domains = $(DOMAINS)
text = true
authenticator = webroot
webroot-path = /home
agree-tos = true
eff-email = true
logs-dir = /home
endef

$(B)/cli.ini: ../.gce.env
	@$(Gcmd) 'echo "$(certbotConfig)" | \
 docker run --rm --interactive \
 --mount $(MountLetsencrypt) \
 --entrypoint "sh" $(PROXY_IMAGE) \
 -c "cat - > /etc/letsencrypt/cli.ini"'
	@$(Gcmd) '\
 docker run --rm --mount $(MountLetsencrypt) --entrypoint "sh" $(PROXY_IMAGE) \
 -c "cat /etc/letsencrypt/cli.ini"' | tee $@

.PHONY: cb-dry-run
cb-dry-run:
	@$(Gcmd) 'docker run -t --rm \
 --mount type=volume,source=static-assets,target=/home \
 --mount $(MountLetsencrypt) \
 --network $(NETWORK) \
 certbot/certbot certonly --dry-run --expand'

.PHONY: certonly
certonly:
	@$(Gcmd) 'docker run -t --rm \
 --mount type=volume,source=static-assets,target=/home \
 --mount $(MountLetsencrypt) \
 --network $(NETWORK) \
 certbot/certbot certonly --expand'

.PHONY: reload
reload: 
	@$(Gngx) './sbin/nginx -s reload'

.PHONY: cb-renew
cb-renew: $(B)/nginx.reload

$(B)/nginx.reload: $(B)/certs.renew
	@mkdir -p $(dir $@)
	@grep -oP 'Cert not yet due for renewal' $< || \
 $(Gngx) './sbin/nginx -s reload' | tee $@

$(B)/certs.renew:
	@mkdir -p $(dir $@)
	@$(Gcmd) 'docker run -t --rm \
 --mount type=volume,source=static-assets,target=/home \
 --mount $(MountLetsencrypt) \
 --network $(NETWORK) \
 certbot/certbot renew' | tee $@

.PHONY: cb-info
cb-info:
	@$(Gcmd) 'docker run -t --rm \
 --mount type=volume,source=static-assets,target=/home \
 --mount $(MountLetsencrypt) \
 --network $(NETWORK) \
 certbot/certbot certificates'

.PHONY: dig
dig:
	@#dig gmack.nz +nocmd +nostats +noquestion
	@echo '+++++++++++++++++++++++++++++++++++++++++++++++++++'
	@dig @ns-cloud-d1.googledomains.com $(SUBDOMAIN) | grep status
	@echo '+++++++++++++++++++++++++++++++++++++++++++++++++++'
	@echo 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
	@dig @208.67.222.222 $(SUBDOMAIN) | grep status
	@echo 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'

.PHONY: openssl-sni
openssl-sni:
	@openssl s_client -servername $(TLS_COMMON_NAME) -tlsextdebug -msg -connect $(SUBDOMAIN):443
	@2>&1 openssl s_client -connect $(TLS_COMMON_NAME):443 | openssl x509 -noout -text | grep -oP '^\s+\KDNS:.+'

.PHONY: openssl-dates
openssl-dates:
	@echo | openssl s_client -connect $(TLS_COMMON_NAME):443 2>/dev/null | openssl x509 -noout -dates

#############################
## CERTS section
## prefix certs

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
 && $(call gcCopyCerts,$(LETSENCRYPT)/live/$(TLS_COMMON_NAME),cert)  \
 && $(call gcCopyCerts,$(LETSENCRYPT)/live/$(TLS_COMMON_NAME),fullchain)  \
 && $(call gcCopyCerts,$(LETSENCRYPT)/live/$(TLS_COMMON_NAME),chain)  \
 && $(call gcCopyCerts,$(LETSENCRYPT)/live/$(TLS_COMMON_NAME),privkey)  \
 && $(call gcCopyCerts,$(LETSENCRYPT),dh-param) \
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
