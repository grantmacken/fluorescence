
DEX := docker exec $(XQ)
ESCRIPT := $(DEX) xqerl escript
EVAL := $(DEX) xqerl eval

BindMountBuild := type=bind,target=/tmp,source=$(CURDIR)/$(B)

compiledLibs := 'BinList = xqerl_code_server:library_namespaces(),\
 NormalList = [binary_to_list(X) || X <- BinList],\
 io:fwrite("~1p~n",[lists:sort(NormalList)]).'

##################################################################
# https://ec.haxx.se/usingcurl/usingcurl-verbose/usingcurl-writeout

WriteOut := '\
response code [ %{http_code} ]\n\
content type  [ %{content_type} ]\n\
SSL verify    [ %{ssl_verify_result} ] should be zero \n\
remote ip     [ %{remote_ip} ]\n\
local ip      [ %{local_ip} ]\n\
speed         [ %{speed_download} ] the average download speed\n\
SIZE     bytes sent \n\
header   [ %{size_header} ] \n\
request  [ %{size_request} ] \n\
download [ %{size_download} ] \n\
TIMER       [ 0.000000 ] start until \n\
namelookup  [ %{time_namelookup} ] DNS resolution  \n\
connect     [ %{time_connect} ] TCP connect \n\
appconnect: [ %{time_appconnect} ] SSL handhake \n\
pretransfer [ %{time_pretransfer} ] before transfer \n\
transfer    [ %{time_starttransfer} ] transfer start \n\
tansfered   [ %{time_total} ] total transfered '
##################################################################
##########################################
# generic make function calls
# call should result in success or failure
##########################################
Tick  = echo -n "$$(tput setaf 2) ✔ $$(tput sgr0) " && echo -n $1
Cross = echo -n "$$(tput setaf 1) ✘ $$(tput sgr0) " && echo -n $1

GrepOK =  grep -q '$(1)' $(2)

## equals $1,$2
## message $3
IsOK  = if $(call GrepOK,$1,$2) ; \
 then $(call Tick, '- [ $(basename $(notdir $2)) ] $3 ');echo;true; \
 else $(call Cross,'- [ $(basename $(notdir $2)) ] $3 ');echo;false;fi

fHeader = $(patsubst %/$(1),%/headers-$(1),$(2))
# 1=file 2=headerKey
HasHeaderKey  = grep -q '^$(2)' $(1)
# 1=file 2=key 3=value
HasKeyValue   = grep -oP '^$2: \K(.+)$$' $1 | grep -q '^$3'

HeaderKeyValue =  echo "$$( grep -oP '^$2: \K(.+)$$' $1 )"

IsLessThan = if [[ $1 -le $2 ]] ; \
 then $(call Tick, '- [ $1 ] should be less than  [ $2 ] ');echo $3;true; \
 else $(call Cross,'- [ $1 ] should NOT be less than [ $2 ] ');echo $3;false;fi

ServesHeader   = if $(call HasHeaderKey,$1,$2); \
 then $(call Tick, '- header [ $2 ] ');echo $3;true; \
 else $(call Cross,'- header [ $2 ] ');echo $3;false;fi

NotServesHeader   = if $(call HasHeaderKey,$1,$2); \
 then $(call Cross, '- not ok [ $2 ] should NOT be served');echo;false; \
 else $(call Tick,'- OK! the header [ $2 ] is not being served');echo;true;fi

HasHeaderKeyShowValue = \
 if $(call HasHeaderKey,$1,$2);then $(call Tick, "- header $2: " );$(call HeaderKeyValue,$1,$2);\
 else $(call Cross, "- header $2: " );false;fi

ServesContentType = if $(call HasHeaderKey,$(1),$(2)); then \
 if $(call HasKeyValue,$1,$2,$3); \
 then $(call Tick, '- header [ $2 ] should have value [ $3 ] ');echo ;true; \
 else $(call Cross,'- header [ $2 ] should value [ $3 ] ');echo;false;fi\
 else $(call Cross,'- header [ $2 ] should have value [ $3 ] ');echo;false;fi

#####################################
### For Curl Tests only when xq is up
####################################
xqAddress != docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(XQERL_CONTAINER_NAME)  2>/dev/null || true

# xqResolve := --resolve $(DOMAIN):$(XQERL_PORT):$(xqAddress)
xqResolve := --resolve xq:$(XQERL_PORT):$(xqAddress)

URL := http://xq:$(XQERL_PORT)
# URL := http://$(xqAddress):$(XQERL_PORT)
GET = curl --silent --show-error \
 --write-out $(WriteOut) \
  $(xqResolve) \
 --dump-header $(dir $2)/headers-$(notdir $2) \
 --output $(dir $2)/doc-$(notdir $2) \
 $(URL)/$(DOMAIN)$1 > $2


locationHeader = $(shell grep -oP 'location:.+/\K/($(DOMAIN)(.+)?$$)' $1 )

locationGET = curl --silent --show-error \
 $(xqResolve) \
 $(URL)$1


#############################

#POST = curl --silent --show-error \
# --write-out $(WriteOut) \
#  $(xqResolve) \
# --dump-header $(dir $2)/headers-$(notdir $2) \
# --output $(dir $2)/output-$(notdir $2) \
# --data-binary @- \
# $(URL)$1 | tee $2 && echo


xmlPOST = curl --silent --show-error \
 --header 'Content-Type: application/xml' \
 --write-out $(WriteOut) \
  $(xqResolve) \
 --dump-header $(dir $@)$(basename $(notdir $@)).header \
 --output $2 \
 --data-binary @- \
 $(URL)/$(DOMAIN)$1






############################
