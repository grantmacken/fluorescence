PROXY_IMAGE = $(PROXY_DOCKER_IMAGE):$(NGX_VER)
XQERL_IMAGE = $(XQERL_DOCKER_IMAGE):$(XQ_VER)
XQ := $(XQERL_CONTAINER_NAME)
NGX := $(PROXY_CONTAINER_NAME)

ifeq ($(origin GITHUB_ACTIONS),undefined)
 GITHUB_ACTIONS := $(EMPTY)
endif

T := .tmp
T := .tmp

EMPTY :=
SPACE := $(EMPTY) $(EMPTY)
DOT := .
COMMA := ,

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

