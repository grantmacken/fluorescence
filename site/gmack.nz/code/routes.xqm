module namespace routes = 'http://gmack.nz/#routes';
declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace http = "http://expath.org/ns/http-client";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare namespace err = "http://www.w3.org/2005/xqt-errors";
(:  test views:  render libs :)
(: import module namespace note = "http://gmack.nz/#render_note"; :)
(: import module namespace feed = "http://gmack.nz/#render_feed"; :)
import module namespace res = "http://gmack.nz/#req_res";
import module namespace maps = "http://gmack.nz/#maps";
import module namespace render = "http://gmack.nz/#render";
import module namespace posts = "http://gmack.nz/#posts";

declare namespace cm="http://commonmark.org/xml/1.0";
declare namespace prob="http://xq/#problem";

declare variable $routes:container := 'xq';
declare variable $routes:domain := 'gmack.nz';
declare variable $routes:dbBase  := string-join(('http:','',$routes:container,$routes:domain),'/');
declare variable $routes:pubBase := string-join(('https:','',$routes:domain),'/');
declare variable $routes:ok := res:status(200);
declare variable $routes:ohNo := res:not_found();
declare variable $routes:author := maps:myCard();

declare
  %rest:path("/gmack.nz/")
  %rest:GET
  %rest:produces("text/html")
  %output:method("html")
function routes:home(){
 try {
  let $sCollection := 'home'
  let $sItem := 'index'
  let $sType := 'entry'
  let $pubURL := string-join(($routes:pubBase,$sCollection,$sItem),'/' )
  let $dbCollection := string-join(($routes:dbBase,$sType,$sCollection),'/' )
  let $dbItem  := string-join(($routes:dbBase,$sType,$sCollection,$sItem),'/' )
  let $errDetail := ``[could not find HTTP resource at `{$pubURL}` ]``
  let $map := 
    if ( $dbItem = uri-collection( $dbCollection ) )
    then ( db:get( $dbItem ) )
    else (error(xs:QName( 'ERROR' ), 'description' , map { 'status': 404, 'detail': $errDetail }) )

  let $render :=
   try {
    $map =>  render:home()
   } catch * { 
      error ( 
        xs:QName( 'ERROR' ), 
        'could not render home page', 
        map { 'status': 404,
              'detail': 'TODO errors in render code' 
  })}



(:
  let $QName := QName("http://gmack.nz/#render",$sCollection)
  let $fRender := 
   try { 
   function-lookup($QName,1)
   } catch * {error(xs:QName( 'ERROR' ), 'description' , map { 'status': 404, 'detail': 'TODO need to build  render code' })}

  let $HTML :=
    $map =>  $fRender()
   } catch * {error(xs:QName( 'ERROR' ), 'description' , map { 'status': 404, 'detail': 'TODO errors in render code' })}


  let $renderFunc := function-name($fRender)
:)
return (
  $routes:ok,
  $render
 )} catch * {(
  map { 'code' : $err:code,
        'description' : $err:description,
        'value' : $err:value
      } => res:htmlErr(),
  map { 'code' : $err:code,
        'description' : $err:description,
        'value' : $err:value
      } => render:problem()
  )}
};

declare
  %rest:path("/gmack.nz/_template")
  %rest:GET
  %rest:produces("text/html")
  %output:method("html")
function routes:template(){
 try {
  let $sCollection := 'article'
  let $sItem := 'another-title'
  let $sType := 'entry'
  let $pubURL       := string-join(($routes:pubBase,$sCollection,$sItem),'/' )
  let $dbCollection := string-join(($routes:dbBase,$sType,$sCollection),'/' )
  let $dbItem       := string-join(($routes:dbBase,$sType,$sCollection,$sItem),'/' )
  let $map := 
    if ( $dbItem = uri-collection( $dbCollection ) )
    then ( db:get( $dbItem ) )
    else ( error( xs:QName( 'ERROR' ),
                  'not found',
                  map { 'status': 404,
                        'detail':``[could not find HTTP resource at `{$pubURL}` ]``}
          ))

  (: render part :)
  let $fName := if ( $sItem eq 'index' )
                then ( $sCollection || '_' || $sItem )
                else ( $sCollection )
  let $QName := QName( "http://gmack.nz/#render", $fName )
  let $fRender :=
   try {
   function-lookup($QName,1)
   } catch * { 
       error ( 
         xs:QName( 'ERROR' ),
         'not implimented',
         map { 'status': 501,
              'detail': 'TODO need to build  render code' 
            }
         )
      }
  let $render :=
   try {
    $map =>  $fRender()
   } catch * {
       error (
         xs:QName( 'ERROR' ), 
         'could not render page', 
         map { 'status': 404,
               'detail': 'TODO errors in render code' 
           }
        )
     }
return (
  $routes:ok,
  $render
 )} catch * {(
  map { 'code' : $err:code,
        'description' : $err:description,
        'value' : $err:value
      } => res:htmlErr(),
  map { 'code' : $err:code,
        'description' : $err:description,
        'value' : $err:value
      } => render:problem()
  )}
};

(:
if ( $err:value instance of map(*) ) then (
      'value' : $err:value
      ) else (
      'value' : ''
      )
:)

declare
  %rest:path("/gmack.nz/{$sCollection}")
  %rest:GET
  %rest:produces("text/html")
  %output:method("html")
function routes:collectionIndex( $sCollection ){
 try {
  (:let $sCollection := 'article' :)
  let $sItem := 'index'
  let $sType := 'entry'
  let $pubURL       := string-join(($routes:pubBase,$sCollection),'/' )
  let $dbCollection := string-join(($routes:dbBase,$sType,$sCollection),'/' )
  let $dbItem       := string-join(($routes:dbBase,$sType,$sCollection,$sItem),'/' )
  let $map := 
    if ( $dbItem = uri-collection( $dbCollection ) )
    then ( db:get( $dbItem ) )
    else ( error( xs:QName( 'ERROR' ),
                  'not found',
                  map { 'status': 404,
                        'detail':``[could not find HTTP resource at `{$pubURL}` ]``}
          ))


  let $sItem := 'index'
  let $sType := 'entry'
  let $pubURL := string-join(($routes:pubBase,$sCollection,$sItem),'/' )
  let $dbCollection := string-join(($routes:dbBase,$sType,$sCollection),'/' )
  let $dbItem  := string-join(($routes:dbBase,$sType,$sCollection,$sItem),'/' )
  let $errDetail := ``[could not find HTTP resource at `{$pubURL}` ]``
  let $map := 
    if ( $dbItem = uri-collection( $dbCollection ) )
    then ( db:get( $dbItem ) )
    else (error(xs:QName( 'ERROR' ), 'description' , map { 'status': 404, 'detail': $errDetail }) )
 (: render part :)
  let $fName := if ( $sItem eq 'index' )
                then ( $sCollection || '_' || $sItem )
                else ( $sCollection )
  let $QName := QName( "http://gmack.nz/#render", $fName )
  let $fRender :=
   try {
   function-lookup($QName,1)
   } catch * { 
       error ( 
         xs:QName( 'ERROR' ),
         'not implimented',
         map { 'status': 501,
              'detail': 'TODO need to build  render code' 
            }
         )
      }
  let $render :=
   try {
    $map =>  $fRender()
   } catch * {
       error (
         xs:QName( 'ERROR' ), 
         'could not render page', 
         map { 'status': 404,
               'detail': 'TODO errors in render code' 
           }
        )
     }
return (
  $routes:ok,
  $render
 )} catch * {(
  map { 'code' : $err:code,
        'description' : $err:description,
        'value' : $err:value
      } => res:htmlErr(),
  map { 'code' : $err:code,
        'description' : $err:description,
        'value' : $err:value
      } => render:problem()
  )}
};


declare
  %rest:path("/gmack.nz/{$sCollection}/{$sItem}")
  %rest:GET
  %rest:produces("text/html")
  %output:method("html")
function routes:collection-item( $sCollection, $sItem ){
 try {
  let $sType := 'entry'
  let $pubURL       := string-join(($routes:pubBase,$sCollection,$sItem),'/' )
  let $dbCollection := string-join(($routes:dbBase,$sType,$sCollection),'/' )
  let $dbItem       := string-join(($routes:dbBase,$sType,$sCollection,$sItem),'/' )
  let $map := 
    if ( $dbItem = uri-collection( $dbCollection ) )
    then ( db:get( $dbItem ) )
    else ( error( xs:QName( 'ERROR' ),
                  'not found',
                  map { 'status': 404,
                        'detail':``[could not find HTTP resource at `{$pubURL}` ]``}
          ))

  (: render part :)
  let $fName := if ( $sItem eq 'index' )
                then ( $sCollection || '_' || $sItem )
                else ( $sCollection )
  let $QName := QName( "http://gmack.nz/#render", $fName )
  let $fRender :=
   try {
   function-lookup($QName,1)
   } catch * { 
       error ( 
         xs:QName( 'ERROR' ),
         'not implimented',
         map { 'status': 501,
              'detail': 'TODO need to build  render code' 
            }
         )
      }
  let $render :=
   try {
    $map =>  $fRender()
   } catch * {
       error (
         xs:QName( 'ERROR' ), 
         'could not render page', 
         map { 'status': 404,
               'detail': 'TODO errors in render code' 
           }
        )
     }
return (
  $routes:ok,
  $render
 )} catch * {(
  map { 'code' : $err:code,
        'description' : $err:description,
        'value' : $err:value
      } => res:htmlErr(),
  map { 'code' : $err:code,
        'description' : $err:description,
        'value' : $err:value
      } => render:problem()
  )}

};


declare
  %rest:path("/gmack.nz/_db")
  %rest:GET
  %rest:produces("application/json")
  %output:method("json")
function routes:db(){
  try  {
  let $sCollection := 'article'
  let $sItem := 'another-title'
  let $sType := 'entry'
  let $dbCollection := string-join(($routes:dbBase,$sType,$sCollection),'/' )
  let $dbItem  := string-join(($routes:dbBase,$sType,$sCollection,$sItem),'/' )
  let $map := 
    if ( $dbItem = uri-collection( $dbCollection ) )
    then ( db:get( $dbItem ) )
    else (error(xs:QName( 'ERROR' ), 'item not in collection' , map { 'status': 404, 'detail': 'TODO' }) )
  return (
  res:status( 200 , "application/json" ),
  $map
  )} catch * { (
  res:status(  $err:value?status , "application/json" ),
  map { 
    'code' : '$err:code',
    'title' : $err:description,
    'status' : $err:value?status,
    'detail' : $err:value?detail
    }
  )
 }
};

declare
  %rest:path("/gmack.nz/_test")
  %rest:GET
  %rest:produces("text/html")
  %output:method("html")
function routes:_test(){
  let $QName := QName("http://gmack.nz/#render",'paragraph')
  let $func := function-lookup($QName,1)
  let $fName := function-name($func)
  (:res is a map:)
  let $res := db:get('http://xq/gmack.nzentry/home/index')
  return (
 $routes:ok,
  element html {
    attribute lang {'en'},
    render:head( map { 'entry' : map  { 'name' : 'index' } } ),
    element body {
      element main {
        attribute class { 'container' },
        element article  {
           element div {  'http://xq/gmack.nz/entry/home/index' = fn:uri-collection('http://xq/gmack.nz/entry/home') },
           element p { doc-available('http://xq/gmack.nz/entry/home/index') },
           element p { unparsed-text-available('http://xq/gmack.nz/entry/home/index') },
           element div { $res instance of map(*)  }
          }
      }
    }
  }
)};

declare
  %rest:path("/gmack.nz/_api")
  %rest:GET
  %rest:produces("application/json")
  %output:method("json")
function routes:_api(){
 try {
  let $x := random:integer(100)
  let $res :=
      if ( $x gt 50 )  then (
         fn:error(xs:QName( 'ERROR' ), 'description' , map { 'status': 500, 'detail': 'over 50'}  )
        ) 
     else (
          "Less than or equal to 50"
        )


  return ( 
  res:status( 200 , "application/json" ),
 map { 'int' : $x, 'res' : $res }
)
 } catch * { (
  res:status(  $err:value?status , "application/json" ),
  map { 
    'code' : '$err:code',
    'title' : $err:description,
    'status' : $err:value?status,
    'detail' : $err:value?detail
    }
  )
 }
};



(:
$fm//node()
  $fm instance of document-node()

  $fm/*/preceding-sibling::comment() instance of comment()
  http://172.18.0.2:8081

  } catch * { error(
   QName('http://xq/err',
         'OhNo'),
   'Unable to parse')
  }
  try{ 
    (
https://tools.ietf.org/html/rfc7807
  let $jFM := posts:fmToMap( $body )
  return 
  if ( $jFM('type') eq  'http:/xq/probs/unparsable' ) then (
    res:status( $jFM?status , "application/xml" ),
    render:problem( $jFM )
    )
  else (
    fn:put($body, 'http://xq/gmack.nz/posts/' || 'test.xml' ),
    res:status( 200 , "application/xml" ),
    $jFM instance of map(*)
    )
:)
declare
  %rest:path("/gmack.nz/_posts")
  %rest:GET
  %rest:produces("application/json")
  %output:method("json")
function routes:get_posts( ){
  map {}
};

declare
  %rest:path("/gmack.nz/_posts")
  %rest:POST('{$xBody}')
  %rest:consumes("application/xml", "text/xml")
  %output:method("json")
  %updating
function routes:posts( $xBody ){
 try {
  let $mOriginFM := posts:fmToMap( $xBody )
  let $doc :=  $xBody/node()
  let $keyCollection :=
      function ( $m as map(*) ) as map(*) {
        posts:getKeyCollection( $m, $mOriginFM, $doc )
      }

  let $keyItem :=
      function ( $m as map(*) ) as map(*) {
        posts:getKeyItem( $m, $mOriginFM, $doc ) 
      }

  let $mModFM := map {} =>
        $keyCollection() =>
        $keyItem()

 let $keyType := 
    function ( $m as map(*) ) as map(*) {
        $m  => 
        map:put('type', 'entry' )
    }

  let $keyName :=
    function ( $m as map(*) ) as map(*) {
      if ( $mOriginFM =>  map:contains( 'title' ) )
      then ( $m => map:put( 'name', $mOriginFM?title ) )
      else ( $m ) (: TODO look for heading or truncated first para :)
    }

  (: unique ID as database URI resource :)
  let $keyUid :=
    function ( $m as map(*) ) as map(*) {
      $m  => 
      map:put( 'uid',
               (  $routes:dbBase,
                 $m?type,
                 $mModFM?collection,
                 $mModFM?item
               ) => string-join('/'))
    }

  let $keyUrl :=
    function ( $m as map(*) ) as map(*) {
      if ( map:get($mModFM,'item') eq 'index' ) 
      then (
        if ( map:get($mModFM,'collection') eq 'home' ) 
        then ($m  => map:put( 'url', $routes:pubBase ) )
        else ( $m  => map:put( 'url', 
                               ( $routes:pubBase,
                                 $mModFM?collection
                               ) => string-join('/')) )
      )
      else (
        $m  => 
        map:put( 'url', ($routes:pubBase,$mModFM?collection,$mModFM?item) => string-join('/'))
      )
    }

 let $keyPublished := 
    function ( $m as map(*) ) as map(*) {
        $m  => 
        map:put( 'published', 
                 current-date() => 
                 adjust-date-to-timezone( xs:dayTimeDuration( $posts:nzTimeZone )) =>
                 string()
               )
    }

  let $keyAuthor :=
      function ( $m as map(*) ) as map(*) {
        if ( 'author' =  map:keys($mOriginFM) ) 
        then ( $m => map:put( 'author', $mOriginFM?author ) )
        else ( $m => map:put( 'author', $routes:author) )
      }

  let $keyContent :=
      function ( $m as map(*) ) as map(*) {
        $m => map:put( 'content', posts:dispatch( $xBody ) )
       }
  let $map :=
      map {} =>
      $keyType() =>
      $keyName() =>
      $keyUid() =>
      $keyUrl() =>
      $keyPublished() =>
      $keyAuthor() =>
      $keyContent()
 (:
   dynamically call render function based on 'collection'
   however if the collection item is 'index'
   then modify to 'collection + underscore + index '
   examples 
   collection: 'home' and item: 'index' call function render:home-index#1
   collection: 'article' item: 'my-interesting -article'  => call function  render:article#1
   however if item is index
   collection: 'article' item: 'index'  => call function  render:article_index#1
  let $QName :=
      if ( map:get($mModFM,'item') eq 'index' ) 
        then ( QName("http://gmack.nz/#render", 
               string-join(( map:get($mModFM,'collection'),
                             map:get($mModFM,'item')  ),'_')) )
      else ( QName("http://gmack.nz/#render",map:get($mModFM,'collection')) ) 
  let $fRender := function-lookup($QName,1)
  let $renderFunc := function-name($fRender)
:)
  return (   
  (: $map => $fRender() => put($map?uid) , :)
  $map => db:put( $map?uid ),
   res:created( $map?url ),
  map:merge(($map, map { 'mod': $mModFM }) )
)
 } catch * { (
  res:status(  $err:value?status , "application/json" ),
  map { 
    'code' : '$err:code',
    'title' : $err:description,
    'status' : $err:value?status,
    'detail' : $err:value?detail
    }
  )
 }

};

(:

  element body {
    element p { ``[ publish url: `{$map?url}`]`` },
    element p { ``[ db uri as uid : `{$map?uid}`]`` },
    element p { ``[ published: `{$map?published}`]`` },
    element p { ``[ item: `{$mModFM?item}`]`` },
    element p { ``[ collection: `{$mModFM?collection}`]`` },
    element p { ``[ render: `{ function-name($fRender)}`]`` },
    $map?content
  }


:)


