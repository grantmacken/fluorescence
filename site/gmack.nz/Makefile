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

BindMountBuild := type=bind,target=/tmp,source=$(CURDIR)/$(B)

# STDOUT
ipAddress != docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(XQ)  2>/dev/null || true
# EXPANSIONS
CURL_IMAGE := curlimages/curl:$(CURL_VER)
CONNECT_TO := --connect-to $(XQ):80:xq.$(NETWORK):$(XQERL_PORT) 
RESOLVE := --resolve $(XQ):$(XQERL_PORT):$(ipAddress)
CURL := docker run --rm --interactive --network $(NETWORK) $(CURL_IMAGE) $(CONNECT_TO)
# CALLS
# call should result in success or failure
Tick  = echo -n "$$(tput setaf 2) ✔ $$(tput sgr0) " && echo -n $1
Cross = echo -n "$$(tput setaf 1) ✘ $$(tput sgr0) " && echo -n $1

.PHONY: build
build: code assets
	@$(if $(GITHUB_ACTIONS),,xdotool search --onlyvisible --name "Mozilla Firefox"  key  Control_L+F5 || true)
	@#xdotool search --onlyvisible --name "Mozilla Firefox"  key  Control_L+F5 || true

.PHONY: clean
clean: clean-code clean-assets clean-scripts

include .inc/*


