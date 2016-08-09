--[[
Coronium LS - redis module
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
local _redis = {}

function _redis.new( config_tbl )
  local redis = require( 'resty.redis' )
  local red, err = redis:new()

  if not red then
    return nil, err
  end

  local r =
  {
    red = red,
    host = host,
    port = port,
    timeout = 20,
    keepalive_max_idle_timeout = 20,
    keepalive_pool_size = 5
  }

  -- Connection
  function r:connect( host, port, pool_size )

    if not self.red then
      return nil, err
    end

    self.host = host
    self.port = port

    local opts = { pool = pool_size }

    local ok, err = self.red:connect( self.host, self.port, opts )
    if not ok then
      return nil, err
    end

    return ok, nil
  end

  -- Timeout
  function r:setTimeout( milliseconds )
    if not milliseconds then
      return self.timeout
    end
    self.timeout = milliseconds or 20
  end

  -- Keepalive
  function r:setKeepalive( max_idle_timeout, pool_size )
    if not max_idle_timeout then
      return self.keepalive_max_idle_timeout, self.keepalive_pool_size
    end
    self.keepalive_max_idle_timeout = max_idle_timeout or 20
    self.keepalive_pool_size = pool_size or 4
  end

  -- Close
  function r:close()
    return self.red:close()
  end

  -- TODO

  return r
end


return _redis
