xquery version "3.1";
module namespace posts = "http://gmack.nz/#posts";
import module namespace  newBase60  = "http://gmack.nz/#newBase60";

declare namespace cm ="http://commonmark.org/xml/1.0";

declare variable $posts:version  := 'v0.0.1';
declare variable $posts:nzTimeZone  := 'PT12H';

(:~
establish publish dates
@return map
:)
declare
function posts:pubDateTime() as map(*){
 let $dateTime := 
            current-dateTime() => 
            adjust-dateTime-to-timezone(xs:dayTimeDuration($posts:nzTimeZone))
let $bDate := $dateTime =>
    newBase60:dateToInteger() => 
    newBase60:encode()
let $bTime := $dateTime => 
                newBase60:timeToInteger() => 
                newBase60:encode()
let $dtStamp := concat(string($bDate), 
                string($bTime))
return 
 map { 
  'dtStamp' : $dtStamp,
  'dateTime' : $dateTime
 }
};

(:~
convert frontmatter in commonmark XML to map
if there is frontmatter in the form of a HTML comment block 
which contains a JSON object 
then covert JSON object into xQuery map
translate(., '$', '')
@param  $xCM commonmark XML
@return map
:)
declare
function posts:postKindDiscovery( $body as document-node() ) {
if ( $body//cm:heading[1] instance of element() )
then ( 'article')
else ( 'note')
};

(:~
convert frontmatter in commonmark XML to map
if there is frontmatter in the form of a HTML comment block 
which contains a JSON object 
then covert JSON object into xQuery map
@param  $xCM commonmark XML
@return map
:)
declare
function posts:fmToMap( $body as document-node() ) as map(*) {
 try{ 
   (
    $body/cm:document/cm:html_block[1]/string() =>
    concat('<dummy />' ) =>
    parse-xml-fragment()
    )/*/preceding-sibling::comment() =>
    string() =>
    parse-json()
  } catch * {
   error(xs:QName( 'ERROR' ),
         'could not parse front matter', 
         map { 'status': 400, 
               'detail': 'check frontmatter formatting in markdown document'}  
      )
  }
};

declare
function posts:getKeyCollection( $m, $mOriginFM, $doc ) as map(*) {
 try{ 
  if ( $mOriginFM => map:contains('collection') ) 
    then ( $m => map:put( 'collection', 
                          $mOriginFM?collection => 
                          normalize-space() =>
                          translate(' ','-')) )
  else if ( $mOriginFM => map:contains('slug') ) 
    then  ( $m => map:put( 'collection','article') )
  else if ( $doc//cm:heading[1] instance of element() )
    then  ( $m => map:put( 'collection','article') )
  else ( $m => map:put( 'collection', 'note' ) )
    } catch * {
   error(xs:QName( 'ERROR' ),
         'could not establish item for collection', 
         map { 'status': 400, 
               'detail': 'try a title in frontmatter'}  
      )
  }
};

declare
function posts:getKeyItem( $m, $mOriginFM, $doc ) as map(*) {
 try{ 
    if ( $mOriginFM => map:contains('index') )
      then ( $m => map:put( 'item', 'index' ) )
    else if ( $m?collection eq 'article' )
      then (
          if ( $mOriginFM => map:contains('slug') ) 
            then  ( $m => map:put( 'item', $mOriginFM?slug => 
                                        normalize-space() => 
                                        translate(' ','-') =>
                                        lower-case() ) )
          else if ( $doc//cm:heading[1]/cm:text[1] instance of element() )
            then  ( $m => map:put( 'item', $doc//cm:heading[1]//cm:text[1]/string() =>
                                        normalize-space() => 
                                        translate(' ','-') =>
                                        lower-case() ) )
          else ( $m)
        )
    else if ( $doc/cm:paragraph[1]/cm:text[1] instance of element() )
      then  ( $m => map:put( 'item', $doc/cm:paragraph[1]/cm:text[1]/string() =>
                                  normalize-space() => 
                                  translate(' ','-') =>
                                  lower-case() ) )
    else ( $m => map:put( 'item', 'todo'))
  } catch * {
   error(xs:QName( 'ERROR' ),
         'could not establish item for collection', 
         map { 'status': 400, 
               'detail': 'try a title in frontmatter'}  
      )
  }
};


(:~
create xQuery map from commonmark text
the map when converted to JSON should 
conform to the JF2 Post Serialization Format
@see https://www.w3.org/TR/jf2/

the map properties should provide rich enough info
to render a HTML document that can be parsed for
mf2 'entry' type properties


entry properties
 - type     entry
 - name     if a 'note' then tuncated first sentence
         if article 
            if not in frontmatter
         use first heading
 - summary   only in post-type article
 - content     from set text -> cmark XML put thru recursive typeswitch
 - published - from server generated dateStamp
 - updated   - from frontmatter status json object
 - author    - always me
 - category  - from front matter
 - url       - points to shorturl permalink @ website
 - uid       - from server generated newBase60 date

extensions
 - post-type
 - status
:)
declare
function posts:entry( $xBody as document-node() ) as map(*) {
try {
 let $mOriginFM := posts:fmToMap( $xBody )
 return $mOriginFM
} catch * {
    map { 
      'type' : 'http://xq/probs/entry',
      'title' : 'could not create entry',
      'status' : 406,
      'details' : 'check frontmatter formatting in markdown document'
    }
  }
};

(:~
recursive typeswitch descent for a commonmark XML document
@see https://github.com/commonmark/commonmark-spec/blob/master/CommonMark.dtd

Block Elements
block_quote|list|code_block|paragraph|heading|thematic_break|html_block|custom_bloc

Inline Elements
text|softbreak|linebreak|code|emph|strong|link|image|html_inline|custom_inline

@param  nodes to process
@return result node
:)
declare
function posts:dispatch( $nodes as node()* ) as item()* {
 for $node in $nodes
  return
    typeswitch ($node)
    case document-node() return (
        for $child in $node/node()
        return ( posts:dispatch( $child) )
        )
     case element( cm:document ) return posts:document( $node )
    (: BLOCK :)
    case element( cm:block_quote ) return 'blockquote' => posts:block( $node )
    case element( cm:list ) return $node => posts:list( )
    case element( cm:item ) return 'li' => posts:block( $node )
    case element( cm:code_block ) return  $node => posts:codeBlock( )
    case element( cm:paragraph ) return  'p' => posts:block( $node )
    case element( cm:heading ) return posts:heading( $node )
    case element( cm:thematic_break )  return 'hr' => posts:block( $node )
    case element( cm:html_block ) return posts:htmlBlock( $node )
    (: INLINE:)
    case element( cm:text ) return $node/text()
    case element( cm:softbreak ) return ( )
    case element( cm:linebreak ) return 'br' => posts:inline( $node ) 
    case element( cm:code ) return 'code' => posts:inline( $node )
    case element( cm:emph ) return 'em' => posts:inline( $node )
    case element( cm:strong ) return 'strong' => posts:inline( $node )
    case element( cm:link ) return posts:link( $node )
    case element( cm:image ) return $node => posts:image( )
    (: case element( cm:html_inline ) return posts:passthru( $node ) :)
    (: case element( cm:custom_inline ) return posts:passthru( $node ) :)
    case element() return posts:passthru( $node )
    default return $node
};

(:~
make a copy of the node to return to dispatch
@param  HTML template node as a node()
@return a copy of the template node
:)
declare
function posts:passthru( $node as node()* ) as item()* {
       element { local-name($node) } {
          for $child in $node
          return posts:dispatch($child/node())
          }
};

declare
function posts:inline( $tag as xs:string, $node as node()* ) as item()* {
element {$tag}{ 
 for $child in $node
 return posts:dispatch($child/node())
 }
};

declare
function posts:block( $tag as xs:string, $node as node()* ) as item()* {
element {$tag}{ 
 for $child in $node
 return posts:dispatch($child/node())
 }
};

declare
function posts:image( $node as node()* ) as item()* {
element img {
    attribute src { $node/@destination/string() },
    attribute title { $node/@title/string() },
    attribute alt { $node/cm:text/string() }
 }
};

declare
function posts:document( $node as node()* ) as item()* {
element article {
 for $child in $node
 return posts:dispatch($child/node())
 }
};

declare
function posts:list( $node as node()* ) as item()* {
if ($node/@type = 'bullet'  ) 
then 
element ul {
 for $child in $node
 return posts:dispatch($child/node())
 }
else
element ol {
 for $child in $node
 return posts:dispatch($child/node())
 }
};

declare
function posts:htmlBlock( $node as node()* ) as item()* {
try{
 if (not( starts-with(normalize-space( $node/string() ),'&lt;!--'))) 
 then () (:$node/string() => util:parse():)
 else ()
 } catch * {()}
};


(: TODO! @info code :)
declare
function posts:codeBlock( $node as node()* ) as item()* {
element pre {
    element code {
        if ( $node/@info  )  
        then ( attribute class { 'language-' || $node/@info/string() })
        else (),
        for $child in $node
        return posts:dispatch($child/node())
    }
 }
};

declare
function posts:heading( $node as node()* ) as item()* {
element { concat('h', $node/@level/string() )  } {
 for $child in $node
 return posts:dispatch($child/node())
 }
};

declare
function posts:link( $node as node()* ) as item()* {
element a { attribute href { $node/@destination },
            attribute title { $node/@title }, 
            normalize-space( $node/string() ) 
           }
};
