######################
###  STATIC ASSETS ###
######################
BuildIconsList := $(patsubst  %.svg,$(B)/$(DOMAIN)/%.svgz,$(wildcard static-assets/icons/*.svg))
BuildStylesList := $(patsubst %.css,$(B)/$(DOMAIN)/%.css.gz,$(wildcard static-assets/styles/*.css))
BuildScriptsList := $(patsubst %.js,$(B)/$(DOMAIN)/%.js.gz,$(wildcard static-assets/scripts/*.js))

.PHONY: assets
assets: $(D)/static-assets.tar

PHONY: init-assets
init-assets:
	@echo '## $@ ##'
	@echo 'set up dir structure on static-assets volume ... '
	@docker run --rm --mount $(MountAssets) --entrypoint "sh" $(PROXY_IMAGE) \
-c '\
 mkdir -p  html/$(DOMAIN)/static-assets/fonts && \
 mkdir -p  html/$(DOMAIN)/static-assets/icons && \
 mkdir -p  html/$(DOMAIN)/static-assets/images && \
 mkdir -p  html/$(DOMAIN)/static-assets/scripts && \
 mkdir -p html/$(DOMAIN)/static-assets/styles'
	@docker run --rm --mount $(MountAssets) --entrypoint "sh" $(PROXY_IMAGE) \
 -c 'ls -R html/$(DOMAIN)'

.PHONY: clean-assets
clean-assets: clean-icons clean-styles clean-scripts
	@echo '## $@ ##'
	@rm -f $(D)/static-assets.tar

$(D)/static-assets.tar: $(BuildStylesList) $(BuildIconsList) $(BuildScriptsList)
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@docker run --rm --mount $(MountAssets) \
 --entrypoint "tar" $(PROXY_IMAGE) czfv - $(PROXY_HOME)/html &>/dev/null > $@
	$(call Tick, '- [ $(basename $(notdir $@)) ] tarred ')
	@echo

###############
### SCRIPTS ###
###############

.PHONY: scripts
scripts: $(BuildScriptsList)

.PHONY: clean-scripts
clean-scripts:
	@echo '## $@ ##'
	@echo 'removing files from build dir ... '
	@rm -frv $(B)/$(DOMAIN)/static-assets/scripts/*
	@echo 'removing files from docker volume ... '
	@docker run --rm --mount $(MountAssets) --entrypoint "sh" $(PROXY_IMAGE) \
 -c 'rm -frv html/$(DOMAIN)/static-assets/scripts/*'

# @cat $< | docker run \
#  --rm \
#  --name gcc \
#  --interactive \
#  elnebuloso/google-closure-compiler --checks-only
# 	@cat $< | docker run \
#  --rm \
#  --name gcc \
#  --interactive \
#  elnebuloso/google-closure-compiler  --formatting PRETTY_PRINT > $@


$(B)/$(DOMAIN)/static-assets/scripts/%.js.gz: static-assets/scripts/%.js
	@echo "##[ $< ]##"
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@cat $< | \
 docker run --rm --interactive docker.pkg.github.com/grantmacken/alpine-zopfli/zopfli:0.0.1 | \
 docker run --rm --interactive --mount $(MountAssets) --entrypoint "sh" $(PROXY_IMAGE) \
 -c 'cat - > $(patsubst $(B)/%,html/%,$@) && cat $(patsubst $(B)/%,html/%,$@)' > $@


#############
### ICONS ###
#############

.PHONY: icons
icons: $(BuildIconsList)



.PHONY: clean-icons
clean-icons:
	@echo '## $@ ##'
	@echo 'removing files from build dir ... '
	@rm -frv $(B)/$(DOMAIN)/static-assets/icons/*
	@echo 'removing files from docker volume ... '
	@docker run --rm --mount $(MountAssets) --entrypoint "sh" $(PROXY_IMAGE) \
 -c 'rm -frv html/$(DOMAIN)/static-assets/icons/*'


$(B)/$(DOMAIN)/static-assets/icons/%.svgz: static-assets/icons/%.svg
	@echo "##[ $* ]##"
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo  ' - use scour to clean and optimize SVG'
	@echo  ' - use zopfli to compress image'
	@cat $< | \
 docker run --rm --interactive docker.pkg.github.com/grantmacken/alpine-scour/scour:0.0.2 | \
 docker run --rm --interactive docker.pkg.github.com/grantmacken/alpine-zopfli/zopfli:0.0.1 | \
 docker run --rm --interactive --mount $(MountAssets) --entrypoint "sh" $(PROXY_IMAGE) \
 -c 'cat - > $(patsubst $(B)/%,html/%,$@) && cat $(patsubst $(B)/%,html/%,$@)' > $@
	@echo "orginal size: [ $$(wc -c $< | cut -d' ' -f1) ]"
	@echo "   gzip size: [ $$(wc -c $@ | cut -d' ' -f1) ]"

######################################
### STYLES: CASCADING STYLE SHEETS ###
######################################

.PHONY: styles
styles: $(BuildStylesList)

.PHONY: clean-styles
clean-styles:
	@echo '## $@ ##'
	@echo 'removing files from build dir ... '
	@rm -frv $(B)/$(DOMAIN)/static-assets/styles/*
	@echo 'removing files from docker volume ... '
	@docker run --rm --mount $(MountAssets) --entrypoint "sh" $(PROXY_IMAGE) \
 -c 'rm -frv html/$(DOMAIN)/static-assets/styles/*'

$(B)/$(DOMAIN)/static-assets/styles/%.css.gz: static-assets/styles/%.css
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo "##[ $(notdir $@) ]##"
	@cat $< | \
 docker run --rm --init --interactive docker.pkg.github.com/grantmacken/alpine-cssnano/cssnano:0.0.3 | \
 docker run --rm --interactive docker.pkg.github.com/grantmacken/alpine-zopfli/zopfli:0.0.1 | \
 docker run --rm --interactive --mount $(MountAssets) --entrypoint "sh" $(PROXY_IMAGE) \
 -c 'cat - > $(patsubst $(B)/%,html/%,$@) && cat $(patsubst $(B)/%,html/%,$@)' > $@
	@echo "orginal size: [ $$(wc -c $< | cut -d' ' -f1) ]"
	@echo "   gzip size: [ $$(wc -c $@ | cut -d' ' -f1) ]"

