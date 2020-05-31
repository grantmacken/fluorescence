######################
###  STATIC ASSETS ###
######################
BuildIconsList := $(patsubst  %.svg,$(B)/$(DOMAIN)/%.svgz,$(wildcard static-assets/icons/*.svg))
BuildStylesList := $(patsubst %.css,$(B)/$(DOMAIN)/%.css.gz,$(wildcard static-assets/styles/*.css))

.PHONY: assets
assets: $(D)/static-assets.tar

.PHONY: clean-assets
clean-assets: clean-icons clean-styles
	@echo '## $@ ##'
	@rm -f $(D)/static-assets.tar

$(D)/static-assets.tar: $(BuildStylesList) $(BuildIconsList)
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@docker run --rm \
 --mount $(MountAssets) \
 --entrypoint "tar" $(PROXY_IMAGE) czfv - $(PROXY_HOME)/html &>/dev/null > $@
	$(call Tick, '- [ $(basename $(notdir $@)) ] tarred ')
	@echo

.PHONY: remove-content-in-assets-volume
remove-content-in-assets-volume:
	@echo '## $@ ##'
	@docker run --rm \
 --mount $(MountAssets) \
 --entrypoint "rm" $(PROXY_IMAGE) -rf ./html/$(DOMAIN)

#############
### ICONS ###
#############


.PHONY: icons
icons: $(BuildIconsList)

.PHONY: clean-icons
clean-icons:
	@echo '## $@ ##'
	@rm -f $(BuildIconsList)
	@rm -fr $(T)/*

$(T)/$(DOMAIN)/static-assets/icons/%.svg: static-assets/icons/%.svg
	@echo "##[ $* ]##"
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo  ' - use scour to clean and optimize SVG'
	@cat $< | docker run --rm --interactive --name scour \
 docker.pkg.github.com/grantmacken/alpine-scour/scour:0.0.2 > $@

$(B)/$(DOMAIN)/static-assets/icons/%.svgz: $(T)/$(DOMAIN)/static-assets/icons/%.svg
	@echo "##[ $* ]##"
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo  ' - use zopfli to compress image'
	@cat $< | docker run \
  --rm \
  --name zopfli \
  --interactive \
  docker.pkg.github.com/grantmacken/alpine-zopfli/zopfli:0.0.1 > $@
	@echo " orginal size: [ $$(wc -c $< | cut -d' ' -f1) ]"
	@echo "   gzip size: [ $$(wc -c  $@ | cut -d' ' -f1) ]"	
	@docker run --rm \
 --mount $(MountAssets) \
 --mount $(MountBuild) \
 --entrypoint "sh" $(PROXY_IMAGE) \
 -c 'mkdir -p "$(dir $(patsubst $(B)/%,html/%,$@))" && \
 cp -v /tmp/$(patsubst $(B)/%,%,$@) $(dir $(patsubst $(B)/%,html/%,$@))'

######################################
### STYLES: CASCADING STYLE SHEETS ###
######################################

.PHONY: styles
styles: $(BuildStylesList)

.PHONY: clean-styles
clean-styles:
	@echo '## $@ ##'
	@rm -f $(BuildStylesList)
	@rm -fr $(T)/*

$(T)/$(DOMAIN)/static-assets/styles/%.css: static-assets/styles/%.css
	@echo "##[ $(notdir $@) ]##"
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo  ' - use cssnano to reduce css file size'
	@cat $< | docker run --rm --init --interactive --name cssnano \
 docker.pkg.github.com/grantmacken/alpine-cssnano/cssnano:0.0.3 > $@

$(B)/$(DOMAIN)/static-assets/styles/%.css.gz: $(T)/$(DOMAIN)/static-assets/styles/%.css
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo "##[ $(notdir $@) ]##"
	@echo  ' - use zopfli to gzip file'
	@cat $< | docker run \
  --rm \
  --name zopfli \
  --interactive \
  docker.pkg.github.com/grantmacken/alpine-zopfli/zopfli:0.0.1 > $@
	@echo "orginal size: [ $$(wc -c $< | cut -d' ' -f1) ]"
	@echo "   gzip size: [ $$(wc -c $@ | cut -d' ' -f1) ]"
	@docker run --rm \
 --mount $(MountAssets) \
 --mount $(MountBuild) \
 --entrypoint "sh" $(PROXY_IMAGE) \
 -c 'mkdir -p "$(dir $(patsubst $(B)/%,html/%,$@))" && \
 cp -v /tmp/$(patsubst $(B)/%,%,$@) $(dir $(patsubst $(B)/%,html/%,$@))'
