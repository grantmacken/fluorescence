xquery version "3.1";
module namespace render = "http://gmack.nz/#render";


declare
function render:home( $map as map(*) ) as element() {
  element html {
    attribute lang {'en'},
    $map =>render:head(),
    element body {
      $map => render:header(),
      element main {
        attribute class { 'container' },
        element article  {
          attribute class { 'h-entry' },
          element h1 {
            attribute class { 'p-name' },
            $map?name
            },
          element article {
            $map?content/node()
            }
          }
        }
      }
    }
};


(:~
@see  https://tools.ietf.org/html/rfc7807
~:)
declare
function render:problem( $map as map(*) ) as element() {
 element problem {
   element type { $map('type') },
   element title { $map('title') },
   element status { $map('status') },
   if ( 'detail' = map:keys( $map ) ) then (element detail { $map('detail') } ) else (),
   if ( 'instance' = map:keys( $map ) ) then (element detail { $map('instance') } ) else ()
  }
};

declare
function render:paragraph( $map as map(*) ) as element() {
  element p {
    ``[ a string  constuctor with  `{$map?var}` supplied via a xquery map ]``   
   }
};

declare
function render:collectionList( $array as array(*) ) as element() {
element ol { 
    $array => 
    array:for-each(
      function ( $item ) {
        let $doc := doc( $item  )
        let $entry := $doc/html/body//article[@class => contains('h-entry') ]
        let $pName :=$entry/h1[@class => contains('p-name')]/string() (: also as title :)
        let $head := $doc/html/head
        let $title := $head/title/string()
        let $permalink := $head/link[@self]/@href/string()
        return (
        element li {
          element a {
            attribute href {$permalink },
            $pName
            }
          }
        )
       }
    )
  }
};



declare
function render:article( $map as map(*) ) as element() {
  element html {
    attribute lang {'en'},
    render:head( $map ),
    element body {
      render:header( $map ),
      render:nav( $map ),
      element main { 
        attribute class { 'container' },
        element article  {
          attribute class { 'h-entry' },
          element h1 {
            attribute class { 'p-name' },
            $map?name
            },
          render:content( $map )
        }
      }
    }
  }
};

declare
function render:article_index( $map as map(*) ) as element() {
  element html {
    attribute lang {'en'},
    render:head( $map ),
    element body {
      render:header( $map ),
      render:nav( $map ),
      element main {
        attribute class { 'container' },
        element article  {
         render:content( $map )
        }
      }
    }
  }
};

declare
function render:html( $map as map(*) ) as element() {
  element html {
    attribute lang {'en'},
    render:head( $map ),
    element body {
      render:header( $map ),
      render:nav( $map ),
      element main { 
        attribute class { 'container' },
        element article  {
          attribute class { 'h-article' },
          element h1 {
            attribute class { 'p-name' },  
            'title' },
          element p { 
            attribute class { 'p-summary' },
            'summary' 
            },
          render:content( $map )
         },
        render:aside( $map )
        },
      render:footer( $map )
    }
  }
};

declare
function render:head( $map as map(*) ) as element() {
element head {
  element meta {
    attribute http-equiv { "Content-Type"},
    attribute content { "text/html; charset=UTF-8"}
    },
  element title { $map?name },
  element meta {
    attribute name { 'viewport' },
    attribute content { 'width=device-width, initial-scale=1' }
    },
  element link {
    attribute href { $map?url },
    attribute rel { 'self' },
    attribute type { 'text/html' }
    },
  element link {
    attribute href { '/styles' },
    attribute rel { 'Stylesheet' },
    attribute type { 'text/css' }
    },
  element link {
    attribute href { $map?author?logo },
    attribute rel { 'icon' },
    attribute type { 'image/svg+xml' }
    }
  }
};

declare
function render:header( $map as map(*) ) as element() {
  element header {
    element img {
      attribute src { $map?author?logo },
      attribute width { '48' },
      attribute height { '48' },
      attribute alt { 'me' }
    },
    element span { $map?author?name }
  }
};

declare
function render:nav( $map as map(*)) as element() {
element nav {
  attribute aria-label { 'Breadcrumb' },
  element ul {
      attribute class { 'breadcrumb' },
      ( $map?url => 
        substring-after('://') =>
        fn:tokenize('/')
      ) =>
      for-each( function( $item ) {
        element li {
          let $uStart := $map?url => substring-before( concat ('/', $item) )
          let $url := $uStart || '/' || $item
          return (
            if ( $url eq $map?url )
            then (
              element span { 
                attribute aria-current { 'page' }, 
                $item 
              } 
             )
            else (
            element a {
                attribute href { $url },
                $item
                }
              )
            )
           }
        })
    }
  }
};


declare
function render:content( $map as map(*)) as element() {
element div {
  attribute class { 'h-content' },
   $map('content')/node()
  }
};

(: string-join(map:keys($map), ' ' ) string-join(map:keys($map), ' ' )
uri-collection($arg as xs:string?)

:)


declare
function render:aside( $map as map(*)) as element() {
element aside {
element p {  'articles: ' },
element ol { 
  uri-collection('http://xq/gmack.nz/article') => 
    for-each(
      function ( $item ) {
        let $doc := doc( $item )
        return (
        element li { 
          element a  { $item }
          }
       )}
    )
  }
}
};


declare
function render:footer( $map as map(*)) as element() {
  element footer {
    attribute title { 'page footer' },
    attribute role  { 'contentinfo' },
    element a {
      attribute href {'/'},
      attribute title { $map('footer-url') },
      $map('footer-url') => substring-after('//')
    },
    ' is the website',
    'owned, authored and operated by ' ,
    element a {
      attribute href { $map('footer-url') },
      attribute title {'author'},
      $map('footer-author')
    }
  }
};

