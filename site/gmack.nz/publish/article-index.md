<!--
{
  "post-status": "updated",
  "published": "2020-06-21+12:00",
  "type": "entry",
  "uid": "http://xq/gmack.nz/article/index",
  "url": "https://gmack.nz/article"
}
-->

# Articles

Eventually this work-in-progress page will generate itself, in the meantime
a list of recent articles are in the aside.

In the meantime, some notes...

## converting markdown documents

Article documents are written in markdown. To get to the browser HTML view of
the document is a bit convoluted.

Our markdown document is first converted to a commonmark XML document via
`cmark` using the `-to xml` flag. It is this XML document that **sent** to the
xqerl server. 

The server attempts create a XDM **map** item, that is rich enough to render a reasonable
HTML view. XDM map items are very flexible containers for data. They can contain
arrays, other maps, XML documents or nodes, and like javascript objects they can
contain functions. Our map has typical document meta 'keys', like the documents 'published' 
 date, 'uid' and 'url'. It also has a 'content' key whose value is a document-node() 
 This document node is transformation of the original sent document.

To get the transform the document body is ran through recursive bespoke `typeswitch` xQuery
function which transforms the commonmark XML into a well formed HTML node. Using
the `typeswitch` xQuery allows a great degree of flexibility as we recursively
walk down the document node tree.


Once the map item is created, the server then stores the XDM map into database.
On the internet when a document is requested, the xqerl server will pull this
stored XDM map item from the xqerl database and pass the item to a 
**template** like render function.

```xquery
declare
function render:article( $map as map(*) ) as element() {
  element html {
    attribute lang {'en'},
    $map =>render:head(),
    element body {
      $map => render:header(),
      $map => render:nav(),
      element main {
        attribute class { 'container' },
        element article  {
          attribute class { 'h-entry' },
          element h1 {
            attribute class { 'p-name' },
            $map?name
            },
            $map?content/node()
          },
         $map => render:aside( )
        },
      $map => render:footer()
      }
    }
};
```




