SHELL=/bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --silent

include .env .version.env .gce.env
include .inc/common.mk

#################################################
### PROXY UP DOWN RESTART and TEST CONFIG ###
#################################################

# docker inspect -f '{{.State.Running}}' $(PROXY_CONTAINER_NAME) | grep -oP '^true' || true
# orExited  != docker ps --all --filter name=$(PROXY_CONTAINER_NAME) --format '{{.Status}}' | grep -oP '^Exited' || true

define proxyRun
docker run --rm \
 --mount $(MountNginxConf) \
 --mount $(MountAssets) \
 --mount $(MountLetsencrypt) \
 --name  $(PROXY_CONTAINER_NAME) \
 --hostname nginx \
 --network $(NETWORK) \
 --publish 80:80 \
 --publish 443:443 \
 --detach \
 $(PROXY_IMAGE)
endef

define proxyNoVolRun
docker run --rm \
 --hostname nginx \
 --network $(NETWORK) \
 --entrypoint "sh" $(PROXY_IMAGE) -c "./sbin/nginx -t" | tee $(@)
endef

.PHONY: check-init
check-init: clean-tmp $(T)/network.check $(T)/certs.check
	@$(proxyNoVolRun)

.PHONY: ngx-up
ngx-up: $(T)/ngx-run/network.check $(T)/ngx-run/certs.check $(T)/ngx-run/config.check $(T)/ngx-run/xqerl-up.check
	@$(if $(call containerRunning,$(NGX)),$(proxyRun),)

.PHONY: ngx-down
ngx-down: ngx-clean
	@echo '##[ $@ ]##'
	@if docker ps --all --format '{{.Names}}' | grep -q $(NGX)
	then
	docker stop $(NGX) &>/dev/null || false
	fi

.PHONY: ngx-clean
ngx-clean:
	@rm -fv $(T)/ngx-run/*

$(T)/ngx-run/xqerl-up.check:
	@mkdir -p $(dir $@)
	@docker ps --all --filter name=$(XQ) --format '{{.Status}}' &> $@
	@if grep -oP '^Up(.+)$$' $@ &>/dev/null ;then \
 $(call Tick, - xqerl: [ $$(tail -1 $@) ]); else \
 $(call Cross,- xqerl: [ down ]) && false; fi
	@echo

$(T)/ngx-run/config.check:
	@mkdir -p $(dir $@)
	@# if config check fails $@ will be removed
	@docker run --rm \
 --mount $(MountNginxConf) \
 --mount $(MountAssets) \
 --mount $(MountLetsencrypt) \
 --network $(NETWORK) --entrypoint 'sh' $(PROXY_IMAGE) -c './sbin/nginx -t' &> $@
	@if grep -oP '^nginx:(.+)ok$$' $@ &>/dev/null ;then\
 $(call Tick, - $$(tail -1 $@)); else \
 $(call Cross, - $$(tail -1 $@)) && false; fi
	@echo

$(T)/ngx-run/certs.check: $(T)/ngx-run/volumes.check
	@mkdir -p $(dir $@)
	@# inspect mounted volume for certs
	@docker run --rm \
--mount $(MountLetsencrypt) \
--entrypoint "sh" $(PROXY_IMAGE) -c 'ls -al $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)' > $@
	@# checks will remove certs.check if failure
	@grep -q 'privkey' $@
	@grep -q 'fullchain' $@
	@grep -q 'chain.pem' $@
	@grep -q 'cert' $@
	@$(call Tick, - certs OK!)
	@echo

$(T)/ngx-run/volumes.check:
	@mkdir -p $(dir $@)
	@# echo '##[ $(notdir $@) ]##'
	@docker volume list  --format "{{.Name}}" > $@
	@$(call MustHaveVolume,nginx-configuration)
	@$(call MustHaveVolume,static-assets)
	@$(call MustHaveVolume,letsencrypt)
	@$(call Tick, - volumes OK!)
	@echo

$(T)/ngx-run/network.check:
	@mkdir -p $(dir $@)
	@# echo '##[ $(notdir $@) ]##'
	@docker network list --format '{{.Name}}' > $@
	@grep -oP '^$(NETWORK)' $@ &>/dev/null || docker network create $(NETWORK)
	@$(call Tick, - network: [ $(NETWORK) ])
	@echo

$(T)/ngx-run/port.check:
	@mkdir -p $(dir $@)
	@echo '##[ $@ ]##'
	@echo -n ' - check TLS port '
	@docker ps --format '{{.Ports}}' | tee $@
	@grep -oP '^(.+)443->\K(443)' $@ || echo  '[ 443 ] OK! can use.'
	@grep -oP '^(.+)443->\K(443)' $@ && echo  '[ 443 ] already in use '

.PHONY: ngx-reload
ngx-reload:
	@echo "## $@ ##"
	@echo ' - local test nginx configuration'
	@docker exec $(PROXY_CONTAINER_NAME) ./sbin/nginx -t
	@echo ' - local restart'
	@docker exec $(PROXY_CONTAINER_NAME) ./sbin/nginx -s reload

.PHONY: ngx-info
ngx-info: $(T)/ngx-run/log-status 	
	@#cat $(T)/log-status
	@echo "$$(docker exec -t $(PROXY_CONTAINER_NAME) ./sbin/nginx -V)" > $(T)/version-info
	@cat $(T)/version-info | grep -oP 'configure arguments: \K.+' | tr ' ' '\n' > $(T)/configure.arguments
	@# cat $(T)/configure.arguments
	@printf %60s | tr ' ' '-' && echo
	@echo 'nginx compiled with'
	@printf %60s | tr ' ' '-' && echo
	@grep -oP '^..with-\K[\w+-_]+$$' $(T)/configure.arguments
	@printf %60s | tr ' ' '-' && echo
	@echo 'nginx dynamic modules'
	@printf %60s | tr ' ' '-' && echo
	@grep -oP '^..add.dynamic.module.+modules/\K.+$$' $(T)/configure.arguments
	@printf %60s | tr ' ' '-' && echo
	@#/bin/grep 'configure' $(T)/version-info

$(T)/ngx-run/log-status:
	@mkdir -p $(dir $@)
	@find $(T)/ -type f | xargs rm -f
	@docker ps --filter name=$(PROXY_CONTAINER_NAME) --format '  name: {{.Names}}' > $@
	@docker ps --filter name=$(PROXY_CONTAINER_NAME) --format  'status: {{.Status}}'  >> $@
	@docker ps --filter name=$(PROXY_CONTAINER_NAME) --format '  ports:  {{.Ports}}' >> $@
	@docker inspect --format='IP addr: {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(PROXY_CONTAINER_NAME) >> $@

$(T)/ngx-run/version-info:
	@echo "$$(docker exec $(PROXY_CONTAINER_NAME) ./sbin/nginx -V)" > $@

