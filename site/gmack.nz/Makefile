SHELL=/bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --silent
#####################
### SITE gmack.nz ###
#####################
include ../../.env ../../.version.env ../../.gce.env
include ../../.inc/common.mk

DOMAIN = gmack.nz
B := .build
D := ../../deploy
MY_BIN_PATH=$(abspath ../../bin)

include .inc/scaffold.mk

# assets content build

.PHONY: build
build: code assets
	@$(if $(GITHUB_ACTIONS),,xdotool search --onlyvisible --name "Mozilla Firefox"  key  Control_L+F5 || true)

.PHONY: watch
watch:
	@while true; do \
        $(MAKE) build; \
        inotifywait -qre close_write . || true; \
    done

.PHONY: clean
clean: clean-code clean-assets

include .inc/code.mk .inc/static-assets.mk  .inc/content.mk  .inc/escripts.mk



##################################


