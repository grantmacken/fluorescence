SHELL=/bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
# MAKEFLAGS += --silent
###################################
include .env .version.env .gce.env
include .inc/common.mk
BindMountDeploy  := type=bind,target=/tmp,source=$(abspath deploy)
###################################
# note: ghToken should be defined on gihub actions
ifeq ($(origin ghToken),undefined)
  ghToken := $(shell cat ../.github-access-token)
endif

.PHONY: help
help:
	@cat << EOF
	ok
	EOF

.PHONY: test
test:
	@pushd tests/proxy &>/dev/null
	@make -silent
	@popd &>/dev/null

.PHONY: up
up: clean-xq-run xq-up clean-code code ngx-up

.PHONY: down
down: ngx-down xq-down

.PHONY: ngx-up
ngx-up:
	@$(MAKE) -f .inc/ngxContainer.mk ngx-up

.PHONY: ngx-down
ngx-down:
	@$(MAKE) -f .inc/ngxContainer.mk ngx-down

.PHONY: ngx
ngx:
	@pushd proxy &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: nxg-clean
ngx-clean:
	@pushd proxy &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: ngx-reload
ngx-reload:
	@$(MAKE) -f .inc/ngxContainer.mk $@

.PHONY: proxy-tests
proxy-tests:
	@pushd tests/proxy &>/dev/null
	@$(MAKE) -silent
	@popd &>/dev/null

.PHONY: proxy-info
proxy-info:
	@pushd tests/proxy &>/dev/null
	@$(MAKE) -silent info
	@popd &>/dev/null

.PHONY: xq-up
xq-up:
	@$(MAKE) -f .inc/xqContainer.mk

.PHONY: clean-xq-run
clean-xq-run:
	@# in case of unclean shutdowm
	@$(MAKE) -f .inc/xqContainer.mk clean-xq-run

.PHONY: xq-down
xq-down:
	@$(MAKE) -f .inc/xqContainer.mk $@

.PHONY: xq-info
xq-info:
	@$(MAKE) -f .inc/xqContainer.mk $@

.PHONY: xq-info-more
xq-info-more:
	@$(MAKE) -f .inc/xqContainer.mk $@

.PHONY: xq-build
xq-build:
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE)
	@popd &>/dev/null

.PHONY: xq-clean
xq-clean:
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE) clean
	@popd &>/dev/null

.PHONY: check-xq-routes
check-xq-routes:
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: check-xq-routes-more
check-xq-routes-more:
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: clean-routes
clean-routes:
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

## will error if error
# .PHONY: watch
# watch:
# @pushd site/$(DOMAIN) &>/dev/null
# while true; do $(MAKE) || true;  \
# inotifywait -qre close_write .  &>/dev/null; done
# popd &>/dev/null

.PHONY: watch-code
watch-code:
	@pushd site/$(DOMAIN) &>/dev/null
	@while true;
	do $(MAKE) || true;
	inotifywait -qre close_write ./code/  &>/dev/null;
	done
	@popd &>/dev/null

.PHONY: watch-assets
watch-assets:
	@pushd site/$(DOMAIN) &>/dev/null
	@while true; do $(MAKE) || true;  \
 inotifywait -qre close_write ./static-assets/  &>/dev/null; done
	@popd &>/dev/null

.PHONY: escript
escript:
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: clean-escript
clean-escript:
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: code
code:
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: recompile
recompile:
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: clean-code
clean-code:
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null


# CREATING AND EDITING CONTENT
#
.PHONY: watch-publish
watch-publish:
	@pushd site/$(DOMAIN) &>/dev/null
	@while true;
	do $(MAKE) publish || true;
	inotifywait -qre close_write ./publish/  &>/dev/null;
	done
	@popd &>/dev/null

.PHONY: publish
publish:
	@pushd site/$(DOMAIN)&>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null


.PHONY: clean-publish
clean-publish:
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: new-article
new-article:
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: assets
assets:
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: init-assets
init-assets:
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: clean-assets
clean-assets:
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: fonts
fonts:
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: scripts
scripts:
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: clean-scripts
clean-scripts:
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: styles
styles:
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: clean-styles
clean-styles:
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

####################################################

.PHONY: xqerl-database-tar-deploy
xqerl-database-tar-deploy:
	@docker run --rm \
 --mount $(MountData) \
 --mount $(BindMountDeploy) \
 --entrypoint "tar" $(XQERL_IMAGE) xvf /tmp/xqerl-database.tar -C /

.PHONY: xqerl-escripts-tar-deploy
xqerl-escripts-tar-deploy:
	@docker run --rm \
 --mount $(MountEscripts) \
 --mount $(BindMountDeploy) \
 --entrypoint "tar" $(XQERL_IMAGE) xvf /tmp/xqerl-escripts.tar -C /

.PHONY: static-assets-tar-deploy
static-assets-tar-deploy:
	@docker run --rm \
 --mount $(MountAssets) \
 --mount $(BindMountDeploy) \
 --entrypoint "tar" $(PROXY_IMAGE) xvf /tmp/static-assets.tar -C /

.PHONY: nginx-configuration-tar-deploy
nginx-configuration-tar-deploy:
	@docker run --rm \
 --mount $(MountNginxConf) \
 --mount $(BindMountDeploy) \
 --entrypoint "tar" $(PROXY_IMAGE) xvf /tmp/nginx-configuration.tar -C /
	@rm -fv $(T)/ngx-run/*
	@docker exec $(NGX) ./sbin/nginx -t
	@docker exec $(NGX) ./sbin/nginx -s reload

.PHONY: pull-pkgs
pull-pkgs:
	#docker pull curlimages/curl:latest
	@echo $(ghToken) | docker login docker.pkg.github.com --username $(REPO_OWNER) --password-stdin
	@docker pull $(XQERL_DOCKER_IMAGE):$(XQ_VER)
	@docker pull $(PROXY_DOCKER_IMAGE):$(NGX_VER)
	@docker pull docker.pkg.github.com/grantmacken/alpine-scour/scour:$(SCOUR_VER)
	@docker pull docker.pkg.github.com/grantmacken/alpine-zopfli/zopfli:$(ZOPFLI_VER)
	@docker pull docker.pkg.github.com/grantmacken/alpine-cssnano/cssnano:$(CSSNANO_VER)

.PHONY: pull-xq-ngx
pull-xq-ngx:
	@echo $(ghToken) | docker login docker.pkg.github.com --username $(REPO_OWNER) --password-stdin
	@docker pull $(XQERL_DOCKER_IMAGE):$(XQ_VER)
	@docker pull $(PROXY_DOCKER_IMAGE):$(NGX_VER)

.PHONY: pull-ngx
pull-ngx:
	@echo $(ghToken) | docker login docker.pkg.github.com --username $(REPO_OWNER) --password-stdin
	@docker pull $(PROXY_DOCKER_IMAGE):$(NGX_VER)

.PHONY: list-compiled-libs
list-compiled-libs:
	@$(ESCRIPT) bin/scripts/$(@).escript

#################
# GCLOUD section
# prefixed gc
# cloud deployment
#################

.PHONY: clean-gc
clean-gc:
	@pushd gcloud &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: gc-init
gc-init:
	@pushd gcloud &>/dev/null
	@$(if $(GITHUB_ACTIONS),$(MAKE) $@,echo ' NOTE: target can only be run on githb actions')
	@popd &>/dev/null

.PHONY: certs-into-vol
certs-into-vol:
	@pushd gcloud &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: certs-check
certs-check:
	@pushd gcloud &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: certs-clean
certs-clean:
	@pushd gcloud &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

#  GCLOUD targets
#  prefix gc

.PHONY: gc-deploy
gc-deploy:
	@pushd gcloud &>/dev/null
	@$(MAKE)
	@popd &>/dev/null

.PHONY: gc-xq-stop
gc-xq-stop:
	@pushd gcloud &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: gc-clean
gc-clean:
	@pushd gcloud &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: gc-xq-up
gc-xq-up:
	@pushd gcloud &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: gc-ngx-restart
gc-ngx-restart:
	@pushd gcloud &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: gc-ngx-up
gc-ngx-up:
	@pushd gcloud &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: gc-once
gc-once:
	@pushd gcloud &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

## CERTBOT targets
# prefix cb

.PHONY: cb-clean
cb-clean:
	@pushd gcloud &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: cb-ini
cb-ini:
	@pushd gcloud &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY:cb-testr
cb-testr:
	@pushd gcloud &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: cb-dry-run
cb-dry-run:
	@pushd gcloud &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: cb-info
cb-info:
	@pushd gcloud &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: cb-renew
cb-renew:
	@pushd gcloud &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null
