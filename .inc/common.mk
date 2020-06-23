
define xqOrderedCompile
xqerl:compile(\"code/src/newBase60.xqm\"),\
xqerl:compile(\"code/src/maps.xqm\"),\
xqerl:compile(\"code/src/req_res.xqm\"),\
xqerl:compile(\"code/src/render.xqm\"),\
xqerl:compile(\"code/src/posts.xqm\"),\
xqerl:compile(\"code/src/routes.xqm\").
endef

compiledLibs := 'BinList = xqerl_code_server:library_namespaces(),\
 NormalList = [binary_to_list(X) || X <- BinList],\
 io:fwrite("~1p~n",[lists:sort(NormalList)]).'

PROXY_IMAGE = $(PROXY_DOCKER_IMAGE):$(NGX_VER)
XQERL_IMAGE = $(XQERL_DOCKER_IMAGE):$(XQ_VER)
XQ := $(XQERL_CONTAINER_NAME)
NGX := $(PROXY_CONTAINER_NAME)

DEX := docker exec $(XQ)
ESCRIPT := $(DEX) xqerl escript
EVAL := $(DEX) xqerl eval

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
MountEscripts   := type=volume,target=$(XQERL_HOME)/bin/scripts,source=xqerl-escripts
MountAssets := type=volume,target=$(PROXY_HOME)/html,source=static-assets
MountNginxConf   := type=volume,target=$(PROXY_HOME)/conf,source=nginx-configuration
MountLetsencrypt := type=volume,target=$(LETSENCRYPT),source=letsencrypt
# bind mount might make volume for escripts
# MountBin     := type=bind,target=$(XQERL_HOME)/bin/scripts,source=$(CURDIR)/bin

define xqRun
 docker run --rm  \
 --mount $(MountCode) \
 --mount $(MountData) \
 --mount $(MountEscripts) \
 --name  $(XQ) \
 --hostname xqerl \
 --network $(NETWORK) \
 --publish $(XQERL_PORT):$(XQERL_PORT) \
 --detach \
 $(XQERL_IMAGE)
endef

define ngxRun
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

Tick  = echo -n "$$(tput setaf 2) ✔ $$(tput sgr0) " && echo -n $1
Cross = echo -n "$$(tput setaf 1) ✘ $$(tput sgr0) " && echo -n $1

# function usage: $(if $(call containerRunning,$(XQ)),yep,nope)
containerRunning = docker ps -q --all --filter name=$1 --format '$1: [ {{.Status}} ]' 2>/dev/null || true

MustHaveVolume = docker volume list --format "{{.Name}}" | \
 grep -q $(1) || docker volume create --driver local --name $(1) &>/dev/null


