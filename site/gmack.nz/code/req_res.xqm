xquery version "3.1";
module namespace res  = "http://gmack.nz/#req_res";

(:
https://tools.ietf.org/html/rfc7807

declare
function res:problem( $sName, $sTitle, $iStatus, $sDetail  ) as map(*) {
  map { 
    'type' : string-join(('http:/xq/probs', $sName),'/' ) ,
    'title' : $sTitle,
    'status' : $iStatus,
    'detail' : sDetail
  }
};
:)
declare
function res:htmlErr( $map as map(*) ) as element() {
 if ( $map?value instance of map(*) ) 
  then ( res:status( xs:integer( $map?value?status ), 
                      $map?description, 
                      'text/html'))
  else ( res:status( 500, 
                    'internal server error', 
                    'text/html') )
};

declare
function res:status() as element() {
  <rest:response>
    <http:response status="200">
      <http:header name="content-type" value="text/html; charset=utf-8"/>
    </http:response>
  </rest:response>
};

declare
function res:status( $status as xs:integer ) as element() {
  <rest:response>
    <http:response status="{string( $status )}">
      <http:header name="Content-Type" value="text/html; charset=utf-8"/>
    </http:response>
  </rest:response>
};

declare
function res:status( $status as xs:integer, $contentType as xs:string ) as element() {
  <rest:response>
    <http:response status="{string( $status )}">
      <http:header name="Content-Type" value="{$contentType}"/>
    </http:response>
  </rest:response>
};

declare
function res:status( $status as xs:integer, $message as xs:string, $contentType as xs:string ) as element() {
  <rest:response>
    <http:response status="{$status => string()}" message="{$message}  ">
      <http:header name="Content-Type" value="{$contentType}"/>
    </http:response>
  </rest:response>
};

declare
function res:created($slocation as xs:string ) as element(  ) {
  <rest:response>
    <http:response status="201" message="Created">
      <http:header name="Location" value="{$slocation}"/>
    </http:response>
  </rest:response>
};

declare
function res:not_found() as element(  ) {
  <rest:response>
    <http:response status="404" message="Not Found">
    </http:response>
  </rest:response>
};

declare
function res:jsonApiRequest( $url, $method, $auth, $accept ) as map(*) {
  let $resp := http:send-request(
        <http:request method='{$method}'>
          <http:header name='Accept' value='{$accept}'/>
          <http:header name='Authorization' value='{$auth}'/>
        </http:request>,
        $url
      )
  let $map := $resp[2]
  return $map
};
