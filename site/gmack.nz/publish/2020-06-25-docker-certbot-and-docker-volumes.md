<!--
{
  "post-status" : "draft",
  "slug" : "docker certbot and docker volumes"
}
-->

# docker certbot and docker volumes

How I use use the certbot/certbot image with my alpine-nginx image to obtain
lets encrypt certs.


## a docker volume named 'letsencrypt'

Our 'nginx' image has been built with 'letsencrypt' and 'certbot' in mind.
The image has pre built a '/etc/letsencrypt' directory which can be a volume
mount point.

We can create amount volume and mount this volume at runtime. 

```
docker volume list | grep -q 'letsencrypt' || docker volume create letsencypt
PROXY_IMAGE=docker.pkg.github.com/grantmacken/alpine-nginx/ngx:0.1.2
docker run --rm --mount type=volume,target=/etc/letsencrypt,source=letsencrypt \
$PROXY_IMAGE ls -al /etc/letsencrypt
```

When mounted this way anything placed in '/etc/letsencrypt/' will now persist in the volume.

## a docker volume named 'static-assets'

Our nginx configuration is set up to handle a
 [HTTP challenge](https://letsencrypt.org/docs/challenge-types/) on port 80

```
server {
  root html;
  index index.html;
  listen 80 default_server;
  listen [::]:80 default_server;
  server_name ~^(www\.)?(?<domain>.+)$;
  # Endpoint used for performing domain verification with Let's Encrypt.
  location /.well-known/acme-challenge {
    default_type "text/plain";
    allow all;
  }
  # Redirect all HTTP requests to HTTPS with a 301 Moved Permanently response.
  location / {
    return 301 https://$http_host$request_uri;
  }
}
```

With the declaration: 

```
 root html;
```

We tell nginx where to for **static** files to serve.
In absolute terms this root is '/usr/local/nginx/html'
Pre built into the 'nginx' image we use is a path to the [HTTP-01
challenge](https://letsencrypt.org/docs/challenge-types/) directories
`/usr/local/nginx/html/.well-known/acme-challenge`

When running the 'ngx' container, this 'root' html directory is a target for
named mount volume called 'static-assets'

```
docker volume list | grep -q 'static-assets' || docker volume create static-assets
docker run --rm \
 --mount type=volume,target=/usr/local/nginx/html,source=static-assets \
 $PROXY_IMAGE ls -R html/.well-known
```

## invoking certbot and the cli.ini'

Certbot commandline options can be in a 'cli.ini' file.
This file is searched for when certbot is invoked. One such location is
`/etc/letsencrypt/cli.ini` which is our mount volume so this
where we will place our `cli.ini`.

When 'ngx' is running we could use `docker cp`
but I'm going to use another **io** pattern which doesn't rely
on a prior running instance.

This is a example certbot cli.ini that I use

```
rsa-key-size = 2048
email =  me@gmail.com
domains = example.com
text = true
authenticator = webroot
webroot-path = /home
agree-tos = true
eff-email = true
logs-dir = /home
```

Now to get the above into our 'letsencrypt' volume we can use 
a container in interactive mode.

```
cat cli.ini | \
 docker run --rm --interactive \
 --mount type=volume,target=/etc/letsencrypt,source=letsencrypt \
 --entrypoint "sh" $PROXY_IMAGE \
 -c "cat - > /etc/letsencrypt/cli.ini"
```

As you can see we can pipe the cli.ini into a container instance.  At runtime
the container instance is mounted onto our letsencrypt volume and the
`entrypoint`is redefined to use 'sh'.  With the container instance in
interactive mode we can pipe the cli.ini into a container instance which can
`cat` the text and then create the '/etc/letsencrypt/cli.ini' file.


## on the www ready for certbot.

On your host get nginx running and serving files. 
At runtime expose ports 80 and 443 on the www. 
Also mount the 'letsencrypt' and 'static-assets' volumes.

```
docker run --rm \
 --mount type=volume,target=/etc/letsencrypt,source=letsencrypt \
 --mount type=volume,target=/usr/local/nginx/html,source=static-assets \
 --name ngx \
 --network wrk \
 --publish 80:80 \
 --publish 443:443 \
 --detach \
 $(PROXY_IMAGE)
```


## using the volumes with certbot

To get our certs we use the docker certbot/certbot image
with two prior established docker volumes.

```
docker run -t --rm \
 --mount type=volume,target=/home,source=static-assets \
 --mount type=volume,target=/etc/letsencrypt,source=letsencrypt \
 --network wrk \
 certbot/certbot certonly --dry-run --expand
```

Take a look at the in our 'cli.ini' the important part to note is this section 

```make
authenticator = webroot
webroot-path = /home
```

The 'ngx' container runtime target `/usr/local/nginx/html` is the contents of
the 'static-assets' volume. 
The certbot container runtime target `/home` is the contents of the 'static-assets'
volume 

```
# the ngx container mount
 --mount type=volume,target=/usr/local/nginx/html,source=static-assets
# the certbot container mount
--mount type=volume,target=/home,source=static-assets
```

'ngx' is running prior to the run of the certbot instance, so the contents of
nginx dir `/usr/local/nginx/html`, will be the same as the contents of the `/home`
directory when running the certbot instance because they use the same source volume.





