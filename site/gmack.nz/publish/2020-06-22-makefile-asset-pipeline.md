<!--
{
  "name": "makefile asset pipeline",
  "post-status": "created",
  "published": "2020-06-21+12:00",
  "type": "entry",
  "uid": "http://xq/gmack.nz/article/makefile-asset-pipeline",
  "url": "https://gmack.nz/article/makefile-asset-pipeline"
}
-->

## A Makefile Asset Pipeline

I am not sure I like Make, but it is the build tool I use.
Other build tools come and go out of fashion,
 but 'Make' is still used widely, is still being iteratively improved upon,
 and once you get the hang of it, it does what you tell it to do.

I use nginx to serve my 'static-assets'. 
Below is a simplified version of my declarative nginx location block for serving my css stylesheets

```nginx
location ~* /styles/.+ {
  rewrite "^/(styles)/(\w+)([?\.]{1}\w+)?$" /static-assets/$1/$2.css break;
  default_type "text/css; charset=utf-8";
  add_header Vary Accept-Encoding;
  gzip off;
  gzip_static  always;
  gunzip on;
  root html/$domain;
}
```

The 'ngx http gzip static' module allows sending pre-compressed files with the “.gz”
filename extension instead of regular files. I use this in conjunction with the 'gunzip' 
module which if required by a client, decompress responses.
So what I am telling nginx to do is, **not** to gzip files on the fly but
instead always use my pre compressed static files. 

 Given the above configuration, whenever I modify a source file in 'static-assets/styles',
I want a compressed gzipped file to end up on my docker *static-assets* volume, that nginx can serve.
However the path to the end result, might consist of many steps, with each step depending on
the result of the previous step. Below is the Makefile example of how I am doing this.

```makefile
# start step': cat src to standard out
# pipe into 'minify step': uses dockerised cssnano image
# pipe into 'gzip step': uses dockerised zopfli image
# pipe into 'store step': uses dockerised nginx image with mounted static assets volume
# pipe to 'done step':  write to local build dir

$(B)/$(DOMAIN)/static-assets/styles/%.css.gz: static-assets/styles/%.css
	@cat $< | \
 docker run --rm --init --interactive \
 docker.pkg.github.com/grantmacken/alpine-cssnano/cssnano:0.0.3 | \
 docker run --rm --interactive \
 docker.pkg.github.com/grantmacken/alpine-zopfli/zopfli:0.0.1 | \
 docker run --rm --interactive \
 --mount $(MountAssets) --entrypoint "sh" $(PROXY_IMAGE) \
 -c 'cat - > $(patsubst $(B)/%,html/%,$@) && cat $(patsubst $(B)/%,html/%,$@)' > $@
	@echo "orginal size: [ $$(wc -c $< | cut -d' ' -f1) ]"
	@echo "   gzip size: [ $$(wc -c $@ | cut -d' ' -f1) ]"
```

So there we have it, a simple continuous asset-pipeline build system using nothing but
docker images and a Makefile.
