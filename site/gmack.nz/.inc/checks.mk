
##################################################################
# https://ec.haxx.se/usingcurl/usingcurl-verbose/usingcurl-writeout
##################################################################

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

.PHONY: check-xq-routes
check-xq-routes: clean-routes home-page

.PHONY: check-xq-routes-more
check-xq-routes-more: home-page-more

.PHONY: clean-routes
clean-routes:
	@rm -frv $(B)/check_route/*

.PHONY: home-page
home-page: $(B)/check_route/home/index
	@echo 'check route [ $@ ]'
	@$(call ServesHeader,$<.header,HTTP/1.1 200, - status OK!)

xxx:	
	@$(call HasHeaderKeyShowValue,$(dir $<)/headers-$(notdir $<),content-type)

.PHONY: home-page-more
home-page-more: $(B)/check_route/home/index
	@echo 'check route [ $@ ]'
	@echo;printf %60s | tr ' ' '-' && echo
	@cat $<
	@echo;printf %60s | tr ' ' '-' && echo
	@cat $(dir $<)/headers-$(notdir $<)
	@echo;printf %60s | tr ' ' '-' && echo
	@cat $(dir $<)/doc-$(notdir $<)
	@echo;printf %60s | tr ' ' '-' && echo
	@$(call ServesHeader,$(dir $<)/headers-$(notdir $<),HTTP/1.1 200, - status OK!)
	@$(call HasHeaderKeyShowValue,$(dir $<)/headers-$(notdir $<),content-type)

$(B)/check_route/home/index:
	mkdir -p $(dir $@)
	$(CURL) --silent --show-error \
 --write-out %{json} -o /dev/null \
 http://xq/$(DOMAIN)/home/index | jq '.' | tee $@.json
	$(CURL) --silent --show-error \
 --dump-header - -o /dev/null \
 http://xq/$(DOMAIN)/home/index | tee $@.header
	$(CURL) --silent --show-error http://xq/$(DOMAIN)/home/index | tee $@.html
	touch $@

##########################################
# generic make function calls
# to check routes
##########################################

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

