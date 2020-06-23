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
  let $dbCollection := string-join(($routes:dbBase,$sCollection),'/' )
  let $dbItem       := string-join(($routes:dbBase,$sCollection,$sItem),'/' )
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
  %rest:path("/gmack.nz/{$sCollection}/{$sItem}")
  %rest:GET
  %rest:produces("text/html")
  %output:method("html")
function routes:collection-item( $sCollection, $sItem ){
 try {
  let $sType := 'entry'
  let $pubURL       := string-join(($routes:pubBase,$sCollection,$sItem),'/' )
  let $dbCollection := string-join(($routes:dbBase,$sCollection),'/' )
  let $dbItem       := string-join(($routes:dbBase,$sCollection,$sItem),'/' )
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
  %rest:path("/gmack.nz/{$sCollection}/{$sItem}")
  %rest:GET
  %rest:header-param( "Accept", "{$mimeType}", "application/json")
  %rest:produces("application/json")
  %output:method("json")
function routes:api-get-json( $mimeType, $sCollection, $sItem ){
try {
  let $sType := 'entry'
  let $dbCollection := string-join(($routes:dbBase,$sCollection),'/' )
  let $dbItem       := string-join(($routes:dbBase,$sCollection,$sItem),'/' )
  let $map := 
    if ( $dbItem = uri-collection( $dbCollection ) )
    then ( db:get( $dbItem ) )
    else ( error( xs:QName( 'ERROR' ),
                  'not found',
                  map { 'status': 404,
                        'detail':``[could not find db resource at `{$dbItem}` ]``}
          ))
return (
  res:status( 200 , "application/json" ),
 $map => 
 map:remove( 'content' ) =>
  map:remove( 'author' )
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
  %rest:path('/gmack.nz/{$sCollection}/{$sItem}')
  %rest:PUT('{$xBody}' )
  %rest:consumes("application/xml", "text/xml")
  %output:method("json")
  %updating
function routes:api-put-xml( $xBody, $sCollection, $sItem ){
try {
  let $mSentFM :=
    if ( $xBody instance of document-node() ) 
      then (
        posts:fmToMap( $xBody )
      )
    else (
      error(xs:QName( 'ERROR' ),
         'did not send commonmark XML document',
         map { 'status': 400,
               'detail': 'failure to PUT document' }
        )
      )


  let $sType := 'entry'
  let $dbCollection := string-join(($routes:dbBase,$sCollection),'/' )
  let $dbItem       := string-join(($routes:dbBase,$sCollection,$sItem),'/' )
  let $hContent :=  map:entry( 'content', posts:dispatch( $xBody  ))
  let $mDB :=
    if ( $dbItem = uri-collection( $dbCollection ) )
    then ( 
      db:get( $dbItem ) => 
      map:remove('content')
    )
    else ( error( xs:QName( 'ERROR' ),
                  'not found',
                  map { 'status': 404,
                        'detail':``[could not find db resource at `{$dbItem}` ]``}
          ))
  let $mDups := map{ 'duplicates': 'use-first'} 
  let $map := 
      map:merge(( $mSentFM, $hContent,  $mDB  ),$mDups ) =>
      map:put( 'post-status', 'updated' )

  return (
  $map => db:put( $map?uid ),
  res:status( 200 , "application/json" ),
  $map => 
  map:remove('author') => 
  map:remove('content')
 )} catch * {(
  map { 'code' : $err:code,
        'description' : $err:description,
        'value' : $err:value
      } => res:jsonErr(),
  map { 'code' : $err:code,
        'description' : $err:description,
        'value' : $err:value
      }
  )}
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

  let $keyPostStatus :=
    function ( $m as map(*) ) as map(*) {
       $m => map:put( 'post-status', 'created') 
    }

  let $keyName :=
    function ( $m as map(*) ) as map(*) {
      if ( $mOriginFM =>  map:contains( 'slug' ) )
      then ( $m => map:put( 'name', $mOriginFM?slug ) )
      else ( $m ) (: TODO look for heading or truncated first para :)
    }

  (: unique ID as database URI resource :)
  let $keyUid :=
    function ( $m as map(*) ) as map(*) {
      $m  => 
      map:put( 'uid',
               ( $routes:dbBase,
                 $mModFM?collection,
                 $mModFM?item
               ) => string-join('/'))
    }

  (: the www pemalink :)
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
      $keyPostStatus() =>
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
  $map => db:put( $map?uid ),
  res:created( $map?uid ),
  $map => 
  map:remove('author') => 
  map:remove('content')
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
           element div {  'http://xq/gmack.nz/home/index' = fn:uri-collection('http://xq/gmack.nz/home') },
           element p { doc-available('http://xq/gmack.nz/home/index') },
           element p { unparsed-text-available('http://xq/gmack.nz/home/index') },
           element div { $res instance of map(*)  }
          }
      }
    }
  }
)};

