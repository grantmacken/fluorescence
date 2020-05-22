
####################
### XQERL UP DOWN ##
####################


xqRunning != docker ps --all --filter name=$(XQ) --format '{{.Status}}' | grep -oP '^Up' || true

define xqRun
 docker run --rm  \
 --mount $(MountCode) \
 --mount $(MountData) \
 --mount $(MountBin) \
 --name  $(XQ) \
 --hostname xqerl \
 --network $(NETWORK) \
 --publish $(XQERL_PORT):$(XQERL_PORT) \
 --detach \
 $(XQERL_DOCKER_IMAGE)
endef

.PHONY: clean-run
clean-run:
	rm -fv $(T)/xq-run/*

.PHONY: up
up: $(T)/xq-run/network.check $(T)/xq-run/volumes.check $(T)/xq-run/xqerl-up.check

.PHONY: down
down: clean-run
	@$(if $(xqRunning),echo -n ' - stopping container: ' && docker stop $(XQ),)

$(T)/xq-run/xqerl-up.check:
	@mkdir -p $(dir $@)
	@docker ps --all --filter name=$(XQ) --format '{{.Status}}' &> $@
	@if ! grep -oP '^Up(.+)$$' $@ &>/dev/null ; then $(xqRun) \
 && sleep 2 \
 && docker ps --all --filter name=$(XQ) --format '{{.Status}}' &> $@ ; fi
	@@if grep -oP '^Up(.+)$$' $@ &>/dev/null ;then\
 $(call Tick, - xqerl: [ $$(tail -1 $@) ]); else \
 $(call Cross,- xqerl: [ down ]) && false; fi
	@$(MAKE) -silent info

$(T)/xq-run/network.check:
	@mkdir -p $(dir $@)
	@docker network list --format '{{.Name}}' > $@
	@grep -oP '^$(NETWORK)' $@ &>/dev/null || docker network create $(NETWORK)
	@$(call Tick, - network: [ $(NETWORK) ]) 
	@echo

MustHaveVolume = docker volume list --format "{{.Name}}" | \
 grep -q $(1) || docker volume create --driver local --name $(1) &>/dev/null

$(T)/xq-run/volumes.check:
	@mkdir -p $(dir $@)
	@# might as well check proxy volumes as well
	@docker volume list  --format "{{.Name}}" > $@
	@$(call MustHaveVolume,xqerl-compiled-code)
	@$(call MustHaveVolume,xqerl-database)
	@$(call MustHaveVolume,static-assets)
	@$(call MustHaveVolume,nginx-configuration)
	@$(call MustHaveVolume,letsencrypt)
	@$(call Tick, - volumes OK!)
	@echo

# secrets:  $(T)/secrets.loaded

#  $(T)/secrets.loaded: $(T)/has.secrets
# 	@# secrets are below the gitrepo so secrets are not under git control
# 	@grep true $< || docker cp ../../../secrets.xml $(XQ):$(XQERL_HOME)/code/src
# 	@grep true $< || $(EVAL) 'xqldb_dml:insert_doc("http://$(XQ)/secrets.xml","./code/src/secrets.xml").'
# 	@grep true $< || docker exec $(XQ) rm ./code/src/secrets.xml 
# 	@$(EVAL) 'xqerl:run("doc-available(\"http://$(XQ)/secrets.xml\")").' > $@


# $(T)/has.secrets:
# 	@$(EVAL) 'xqerl:run("doc-available(\"http://$(XQ)/secrets.xml\")").' > $@

.PHONY: info
info:
	@echo '## $@ ##'
	@docker ps --filter name=$(XQ) --format ' -    name: {{.Names}}'
	@docker ps --filter name=$(XQ) --format ' -  status: {{.Status}}'
	@echo -n '-    port: '
	@docker ps --format '{{.Ports}}' | grep -oP '^(.+):\K(\d{4})'
	@echo -n '- IP address: '
	@docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(XQ)
	@echo;printf %60s | tr ' ' '-' && echo
	@echo -n '- working dir: '
	@$(EVAL) '{ok,CWD}=file:get_cwd(),list_to_atom(CWD).'
	@echo -n '-        node: '
	@$(EVAL) 'erlang:node().'
	@#$(EVAL) 'erlang:nodes().'
	@echo -n '-      cookie: '
	@$(EVAL) 'erlang:get_cookie().'
	@echo -n '-        host: '
	@$(EVAL) '{ok, HOSTNAME } = net:gethostname(),list_to_atom(HOSTNAME).'
	@echo;printf %60s | tr ' ' '-' && echo
	@$(EVAL) $(compiledLibs)
