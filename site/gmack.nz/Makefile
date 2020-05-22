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
include ../../.env
DOMAIN = gmack.nz
XQ := $(XQERL_CONTAINER_NAME)
T := .tmp
R := .tmp/curl_response
P := .tmp/post_response
B := .build
D := ../../deploy
MY_BIN_PATH=$(abspath ../../bin)

EMPTY :=
SPACE := $(EMPTY) $(EMPTY)
DOT := .
COMMA := ,
ifeq ($(origin GITHUB_ACTIONS),undefined)
 GITHUB_ACTIONS := $(EMPTY)
endif

include .inc/scaffold.mk


# shortcut aliases
# targets
# 'make'  first target  is `make build`
# `make assets`
# `make clean-assets`
#
# make: this targets `make xqerl-compiled-code`, the first target
# xqerl-compiled-code
# the tar should be an updated when local files change
# the tar comes from the xqerl-compiled-code volume
# and not the build dir
####################################################################

#include container.mk

.PHONY: build
build: code assets content
	@$(if $(GITHUB_ACTIONS),,xdotool search --onlyvisible --name "Mozilla Firefox"  key  Control_L+F5 || true)

# .PHONY: gh_build
# gh_build: code assets content
# 	@$(if $(GITHUB_ACTIONS),,xdotool search --onlyvisible --name "Mozilla Firefox"  key  Control_L+F5 || true)

.PHONY: watch
watch:
	@while true; do \
        $(MAKE) build; \
        inotifywait -qre close_write . || true; \
    done

include .inc/code.mk
include .inc/static-assets.mk
include .inc/content.mk
include .inc/container.mk
##################################

.PHONY: clean
clean: clean-code clean-assets

