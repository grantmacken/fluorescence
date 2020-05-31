PROXY_IMAGE = $(PROXY_DOCKER_IMAGE):$(NGX_VER)
XQERL_IMAGE = $(XQERL_DOCKER_IMAGE):$(XQ_VER)
XQ := $(XQERL_CONTAINER_NAME)
NGX := $(PROXY_CONTAINER_NAME)

EMPTY :=
SPACE := $(EMPTY) $(EMPTY)
DOT := .
COMMA := ,

ifeq ($(origin GITHUB_ACTIONS),undefined)
 GITHUB_ACTIONS := $(EMPTY)
endif

T := .tmp

# volume mounts
MountCode   := type=volume,target=$(XQERL_HOME)/code,source=xqerl-compiled-code
MountData   := type=volume,target=$(XQERL_HOME)/data,source=xqerl-database
MountAssets := type=volume,target=$(PROXY_HOME)/html,source=static-assets
MountNginxConf   := type=volume,target=$(PROXY_HOME)/conf,source=nginx-configuration
MountLetsencrypt := type=volume,target=$(LETSENCRYPT),source=letsencrypt
# bind mount might make volume for escripts
MountBin     := type=bind,target=$(XQERL_HOME)/bin/scripts,source=$(CURDIR)/bin
# pretty print
Tick  = echo -n "$$(tput setaf 2) ✔ $$(tput sgr0) " && echo -n $1
Cross = echo -n "$$(tput setaf 1) ✘ $$(tput sgr0) " && echo -n $1

# function usage: $(if $(call containerRunning,$(XQ)),yep,nope)
containerRunning = docker ps -q --all --filter name=$1 --format '$1: [ {{.Status}} ]'

MustHaveVolume = docker volume list --format "{{.Name}}" | \
 grep -q $(1) || docker volume create --driver local --name $(1) &>/dev/null
