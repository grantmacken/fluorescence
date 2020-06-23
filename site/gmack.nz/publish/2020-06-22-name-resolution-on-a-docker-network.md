<!--
{
  "name": "name resolution on a docker network",
  "post-status": "updated",
  "published": "2020-06-21+12:00",
  "type": "entry",
  "uid": "http://xq/gmack.nz/article/name-resolution-on-a-docker-network",
  "url": "https://gmack.nz/article/name-resolution-on-a-docker-network"
}
-->

Lets say we have two docker containers, a xQuery application server name 'xq'
and a nginx reverse proxy server named 'ngx', 
when started  have joined a network named 'wrk'.

```shell
docker exec xq nslookup xq.wrk
docker exec xq nslookup ngx.wrk
docker exec xq nslookup twitter.com
```

The reply from 

```
# docker exec xq nslookup ngx.wrk
Server:         127.0.0.11
Address:        127.0.0.11:53

Non-authoritative answer:

Non-authoritative answer:
Name:   ngx.wrk
Address: 172.18.0.3
```

This is telling me docker runs it own internal network
dns resolution service at 127.0.0.11.
Although I am am running an exec a command on 'xq' 
the resolution service 'xq' uses knows other container name and IP addresses
on the internal docker network. The IP Address '172.18.0.3' is
in the range ( 172.16.0.0 - 172.31.255.255 ) that is not directly connected to the internet.




If it can't resolve a name locally it will use the google server
at 8.8.8.8 for external address resolution.

If containers 'xq' and 'ngx' are on the same docker network,
due to the fact docker is doing the name resolution,
we can  **proxy pass** using the URL: **"http://xq"**


```nginx
  location / {
    rewrite ^/?(.*)$ /$domain/$1 break;
    proxy_pass http://xq;
    }
```

On the www 'http://xq' is unreachable. To reach services on 'xq',
requests must be routed via the proxy server gateway.

However with dockerised curl on the **same** host,
you can join the same docker network,
and curl will also be able to resolve container names,
using either the 'connect-to' or 'resolve' flags

```makefile
.PHONY: crl
crl:
	@docker run --rm --interactive --network www curlimages/curl \
    --connect-to xq:80:xq:8081 \
    -H 'Accept: application/json' \
    http://xq/$(DOMAIN)/article/name-resolution-on-a-docker-network |
    jq '.'
```





