<!--
{
  "name": "markdown driven sites",
  "post-status": "update",
  "published": "2020-07-03+12:00",
  "status": "updated",
  "type": "entry",
  "uid": "http://xq/gmack.nz/article/markdown-driven-sites",
  "url": "https://gmack.nz/article/markdown-driven-sites"
}
-->

One of the things I wanted achieve from this site,
was to be able to write content in a markdown document,
and when I saved the document, it would automatically get published.
I soon realised this was not quite what I wanted as I am a useless typist.
What I needed was to have the document around in some sort of 'draft' state.
When I saved the spelling and grammar could be checked, but not published.
What I decided on was a **client** directive in my frontmatter block.

## status: draft

```json
{
  "status": "draft"
}
```

The client has a `watch` on a directory that looks for *writes* to files, If the
markdown *frontmatter* has *draft* status, when writes occur, the client does
**not**  post to the server.  The client will however lint check the content,
and will produce `warnings` regarding the markdown content spelling, grammar and
prose.

## status: create

```json
{
  "status": "create",
  "slug": "markdown driven sites"
}
```

To publish I modify the `status` key to `create`.  To suggest how I want this
document named, there may be an added 'slug' `key` with an associated `value`
When I write to file, the client will post the document content to the posts
endpoint. If the server achieves it's task of creating a new resource, it returns a `201
created` response status and a location header.  The location header value is an
'edit' URI where we can use the HTTP methods
 - PUT to update the resource
 - DELETE to delete the resource.
 - GET  with `Accept` header will return a representation of the resource.

This response is used to update the frontmatter in the origin document.

## status: created

```json
{
  "status": "created",
  "uid": "http://xq/gmack.nz/article/makefile-asset-pipeline"
}
```

With a *created* status,the client treats this like the draft status and does
*not* publish when a write to file occurs. The *uid* key is a unique identifier.
It is the 'location' header value sent by the server when the document is
created, and used by the client as the edit URL where the client can send HTTP
requests to get, update or delete the resource on the server.

## status: update

```json
{
  "status": "update",
  "uid": "http://xq/gmack.nz/article/makefile-asset-pipeline"
}
```

When the markdown frontmatter has a *update* status then 
the client will use the uid to send a HTTP PUT request when a write to file occurs.
If server resource update is successful, the server will send a 200 or 204 response status. 

This header response status is used by the client to update the frontmatter in the origin document. 

## post status: updated

```json
{
  "status": "updated",
  "uid": "http://xq/gmack.nz/article/makefile-asset-pipeline"
}
```

When the markdown frontmatter has a *updated* status, 
then client again treats this like the draft status, and a write to file will *not*
publish the document, however id we change the status to `update`, then
the client will again send a PUT request on a file write. When the client
receives success response from the server, it will revert the 
*update* status to *updated* in the origin document.

## post status: delete

```json
{
  "status": "delete",
  "uid": "http://xq/gmack.nz/article/makefile-asset-pipeline"
}
```

When the markdown frontmatter has a *delete* status,
the client sends a DELETE request to the server.
After the server deletes the resource, it will send a `204 No Content` response. 
If the client receives this response, 
it will change the *delete* status to *deleted* in the origin document.


## post status: fetch

```json
{
  "status": "fetch",
  "uid": "http://xq/gmack.nz/article/makefile-asset-pipeline"
}
```

When the markdown frontmatter has a *fetch* status,
the client send a GET request to the server.
The GET request is made with an`Accept: application/json`
header. The server sends a JSON response, and the client uses
this response to replace the frontmatter in the origin document.

## post status: fetched

```json
{
  "name": "markdown driven sites",
  "published": "2020-07-03+12:00",
  "status": "fetched",
  "type": "entry",
  "uid": "http://xq/gmack.nz/article/markdown-driven-sites",
  "url": "https://gmack.nz/article/markdown-driven-sites"
}
```
