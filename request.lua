--[[
Coronium LS - request module
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

local mod = {}

function req.new( url, port )
  local port = port or 80
  local r =
  {
    url = url,
    port = port
  }
  ---HTTP Request
  -- @req_params { path, method, body, headers }
  -- @timeout_ms
  -- @keepalive_ms
  -- @keepalive_poolsize
  function r:request( req_params, timeout_ms, keepalive_ms, keepalive_poolsize )

    local response = require('response')

    local timeout_ms = timeout_ms or 5000 --5 sec
    local keepalive_ms = keepalive_ms or 30000 --30 secs
    local keepalive_poolsize = keepalive_poolsize or 3

    local httpc = require('resty.http').new()

    local function closeUp()
  		local ok, err = httpc:set_keepalive( keepalive_ms, keepalive_poolsize )
  		if err then
  			if ok == 2 then --== Must close
  				httpc:close()
  			end
  		end
    end

    local headers = req_params.headers or {['Content-Type']='application/json'}
    req_params.headers = headers

    local ok, err = httpc:connect( self.url, self.port )

    if not ok then
      return nil, err
    end

    httpc:set_timeout( timeout_ms )

    if self.port == 443 then
      local session, err = httpc:ssl_handshake()
      if err then
        return response.new( nil, err )
      end
    end

    local res, err = httpc:request( req_params )

    closeUp()

    if not res then
      return response.new( nil, err )
    end

    return response.new( res, nil )
  end

  return r
end

return mod
