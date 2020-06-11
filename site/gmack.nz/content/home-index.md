<!--{
"title" : "somewhere over the rainbow",
"collection" : "home",
"index" : "yep"
}-->

This blog is a rework of a previous project, where I initially started to explore using xqerl for web development projects.
Like every other blog I'll write and about the stuff I am interested in, which will most likely centre around 'declarative markup' tech.
Initially I am going to write about, how I am putting this site together.


<!--
- [x] content generated from markdown documents.
- [x] data stored and retrieved as XDM map items
- [x] the xQuery render module can be seen as a simple HTML template engine 
- [x] the xQuery 'module' contains render functions that use xQuery element constructors to produce HTML pages and fragments
- [x] the xQuery render module should be easy to read and edit
- [x] a map item is passed as singe argument to xQuery render functions
- [x] the map item needs to be rich enough to populate a page


Static Site Generators have become increasingly popular over the last few years. 
One of ideas of ‘SSG’ is that the generator logic can reside in the markdown document,
or via a pre established directory layout. When the generator logic resides in the document, 
it can be a front-matter part at the head of the document.

I have chosen to have a single content directory, with the generator logic
driven by either a front-matter part or derived by looking at the markup content.

With 'SSG', data sources are feed into, or pulled into a template engine 
which uses  'templates' to generate the resulting static html pages. 
The data sources can be inferred from markdown content or front-matter or some 
other pre subscribed manner. 
Whatever the case a author with a prior knowledge of data types that
will be feed the template engine, should be able to easily edit a 
template used to generate the resulting html documents 

The data item I use is in the form of a
[XDM](https://www.w3.org/TR/xpath-datamodel-31) [map item](https://www.w3.org/TR/xpath-datamodel-31/#map-items).

The render templates are written as simple xQuery functions where the data 'map' item gets
passed as a parameter to to functions. 

```xquery
declare
function render:home( $map as map(*) ) as element() {
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

-->


