--[[
Coronium LS - app module
Copyright 2016 C.Byerley

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
]]
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++--

local Cloud = {}; function Cloud.new() local app = {}

--======================================================================--

--== xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--== IMPORTANT!
--== Don't call this module directly, it belongs to nginx
--== xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

--======================================================================--
--== Constants
--======================================================================--
app.version     = '1.3.0'
app.home        = '/home/cloud'
app.lib         = '/usr/local/cloud'
--== HTTP methods
app.GET         = "GET"
app.POST        = "POST"
app.DELETE      = "DELETE"
app.PUT         = "PUT"
--== Content types
app.JSON        = "application/json"
app.TEXT        = "text/plain"
app.HTML        = "text/html"
--== Log constants
app.STDERR      = ngx.STDERR --all
app.WARN        = ngx.WARN
app.INFO        = ngx.INFO
app.NOTICE      = ngx.NOTICE
app.DEBUG       = ngx.DEBUG
--== Sorting constants
app.ASCENDING   = 'ASC'
app.DESCENDING  = 'DESC'
--======================================================================--
--== App Modules
--======================================================================--
app.lang        = require('cloud.lang') --internal translation
app.json        = require('cjson') -- cjson
app.api         = require('cloud.module').api --page request holder
app.mysql       = require('cloud.mysql') -- mysql db
app.mongo       = require('cloud.mongo') -- mongo db
app.error       = require('cloud.error').new --structured error
app.geoip       = require('cloud.geoip') --geo ip meta
app.async       = require('cloud.async') -- async generator
app.job         = require('cloud.job') -- job generator
app.time        = require('cloud.time') --times
app.network     = require('cloud.network').new -- http handler
app.internal    = require('cloud.internal') --cross-module requests
app.template    = require('cloud.template') --templating
--======================================================================--
--== 3rd Party Modules
--======================================================================--
app.lfs         = require( 'lfs' ) -- LuaFileSystem
app.lpeg        = require( 'lpeg' ) -- lpeg parsing lib
app.moses       = require( 'moses' ) -- moses lib
app.crypto      = require( 'crypto' ) --lua crypto lib
app.s3          = require( 'resty.s3' ) -- S3 transfer
app.validator   = require( 'resty.validation' ) -- validation lib
--======================================================================--
--== App Utils
--======================================================================--
app.pp          = require( 'cloud.utils' ).pp -- table pretty print to log
app.sf          = require( 'cloud.utils' ).strf --string.format
app.trim        = require( 'cloud.utils' ).trim --string trim
app.split       = require( 'cloud.utils' ).split --string split
app.uuid        = require( 'cloud.utils' ).uuid --unique id (requires libuuid)
app.jtbl        = require( 'cloud.utils' ).jtable --JSONable table .toJson()
app.tmerge      = require( 'cloud.utils' ).table_merge -- table merging util
app.exists      = require( 'cloud.utils' ).fileExists -- check for file
app.encode      = require( 'cloud.encoding' ).encode --encoding/decoding
app.decode      = require( 'cloud.encoding' ).decode --encoding/decoding
app.jobs        = ngx.shared.jobs --jobs ref shared dict
app.null        = ngx.null --JSONable null for comparisons
app.isAjax      = false --set on request input
--======================================================================--
--== Logging
--======================================================================--
app.log = function( log_str, log_type )
  local log_type = log_type or app.NOTICE
  local log_str = log_str or ""
  local in_type = type( log_str )

  if in_type == 'function' or in_type == 'userdata' then
    ngx.log( log_type, ( "Could not log "..in_type ) )
  else
    if in_type == 'table' then
      local res = app.encode.json( log_str )
      ngx.log( log_type, res )
    else
      log_str = tostring( log_str )
      ngx.log( log_type, log_str )
    end
  end
end
app.print = app.log
--======================================================================--
--== Output factories, you can also `return` most data as-is
--======================================================================--
app.result = function ( resultData, resultLabel )
  local resultLabel = resultLabel or 'result'
  local t = {}
  t[ resultLabel ] = resultData or {}
  return t
end
--aliases
app.response  = app.result
--======================================================================--
--== Specialized Methods (privates)
--======================================================================--
app._outputResult = function( success_data, content_type, headers, status_type )
  local content_type = content_type or app.JSON
  app._output( app.result( success_data ), content_type, headers, status_type )
end

app._outputError = function( error_msg, error_code, content_type, headers, status_type )
  local error_code = error_code or -99
  local content_type = content_type or app.JSON
  app._output( app.error( error_msg, error_code ), content_type, headers, status_type )
end
--======================================================================--
--== Master Output
--======================================================================--
app._output = function( response_str, content_type, headers, status_type )
  local response_str = response_str

  local content_type = content_type or app.JSON
  ngx.header.content_type = content_type

  if headers then
    for k, v in pairs( headers ) do
      ngx.header[ k ] = v
    end
  end

  local status_type = status_type or ngx.HTTP_OK
  ngx.status = status_type

  if content_type == app.JSON then
    response_str = app.encode.json( response_str )
    if not response_str then
      response_str = app.encode.json( app.error( "Response string nil. JSON parse error." ) )
    end
  end

  ngx.say( response_str )
end
--======================================================================--
--== Cloud
return app; end; return Cloud;
--======================================================================--
