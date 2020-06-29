xquery version "3.1";
module namespace render = "http://gmack.nz/#render";

declare
function render:home_index( $map as map(*) ) as element() {
  element html {
    attribute lang {'en'},
    $map => render:head(),
    element body {
      $map => render:header(),
      $map => render:nav-breadcrumb(),
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
         $map => render:aside()
        },
      $map => render:footer()
      }
    }
};

declare
function render:article_index( $map as map(*) ) as element() {
  element html {
    attribute lang {'en'},
    $map =>render:head(),
    element body {
      $map => render:header(),
      $map => render:nav-breadcrumb(),
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

declare
function render:article( $map as map(*) ) as element() {
  element html {
    attribute lang {'en'},
    $map =>render:head(),
    element body {
      $map => render:header(),
      $map => render:nav-breadcrumb(),
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

(:~
@see  https://tools.ietf.org/html/rfc7807
~:)
declare
function render:problem( $map as map(*) ) as element() {
  element html {
    attribute lang {'en'},
    element head {
      element title { 'ERROR: We Have a Problem' }
      },
    element body {
        element h1 { 'We Have a Problem' },
        element dl {
          element dt { 'code' },
          element dd { $map?code },
          element dt { 'description' },
          element dd { $map?description },
          if ( $map?value instance of map(*) ) then (
            element dt { 'detail' },
            element dd { $map?value?detail },
            element dt { 'status' },
            element dd { $map?value?status }
            )
          else ()
          }
        }
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
function render:html( $map as map(*) ) as element() {
  element html {
    attribute lang {'en'},
    render:head( $map ),
    element body {
      render:header( $map ),
      render:nav-breadcrumb( $map ),
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
  if ( $map => map:contains('summary') ) then 
    element meta {
      attribute name { 'description' },
      attribute content { $map?summary }
    }
  else (),
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
    attribute href { '/styles/main' },
    attribute rel { 'stylesheet' },
    attribute type { 'text/css' }
    },
  element link {
    attribute href { '/styles/lists' },
    attribute rel { 'stylesheet' },
    attribute type { 'text/css' }
    },
  element link {
    attribute href { '/styles/prism' },
    attribute rel { 'stylesheet' },
    attribute type { 'text/css' }
    },
  element link {
    attribute href { $map?author?logo },
    attribute rel { 'icon' },
    attribute type { 'image/svg+xml' }
    },
  element script {
    attribute src { '/scripts/prism' }
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
    $map?author?name
  }
};

declare
function render:nav-breadcrumb( $map as map(*)) as element() {
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
                then ( element span { attribute aria-current { 'page' }, $item } )
              else ( element a { attribute href { $url }, $item } )
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

declare
function render:aside( $map as map(*)) as element() {
let $seqEntries := 'http://xq/gmack.nz/article' => uri-collection()
let $entryCount := $seqEntries => count()
return (
element aside {
  element nav {
    attribute aria-labelledby { 'articles' },
    element h2 {
      attribute id { 'articles' },
      ``[ other articles ]``  
      },
    element ul { 
      attribute class { 'vertical-list' },
      $seqEntries => for-each(
         function ( $dbURI ) {
           let $item := $dbURI => db:get()
           return (
            if ( $map?url eq $item?url ) then ()
            else (
              element li { 
                element a {
                  attribute href { $item?url  },
                  $item?name
                  }
                }
            )
          )
        }
      )
    }
  }
}
)};


declare
function render:footer( $map as map(*)) as element() {
  let $sURL   := $map?author?url
  let $sName := $map?author?name
  return (
  element footer {
    attribute title { 'page footer' },
    attribute role  { 'contentinfo' },
    element a {
      attribute href { $sURL },
      $sURL => substring-after('//')
    },
    '&#8239;a website owned, authored and operated by&#8239;' ,
    element a {
      attribute href { $sURL },
      attribute title {'author'},
      $sName
    }
  }
)};

