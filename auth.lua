--[[
Coronium LS - auth module
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

--== xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--== IMPORTANT!
--== Don't call this module directly, it belongs to nginx
--== xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
local auth = {}

function auth._checkHash()
  local normalized = ngx.ctx.host .. ngx.ctx.app_key .. ngx.var.uri
  local hash = ngx.md5(normalized)

  if tostring(hash) ~= tostring(ngx.ctx.cloud_hash) then
    return nil
  end

  return true
end

function auth.request(req)

  local url = require('socket.url')

  local method = req.get_method()
  local headers = req.get_headers()

  ngx.ctx.host        = headers['Host'] or nil
  ngx.ctx.app_key     = headers["X-Cloud-Key"] or nil
  ngx.ctx.cloud_key   = headers["X-Cloud-Master"] or nil
  ngx.ctx.cloud_hash  = headers['X-Cloud-Hash'] or nil

  --open cloud config (from support dir)
  local cloud_config = require('cloudconfig')

  --check for cloud level reject flag
  if cloud_config.reject_all then
    return ngx.exit(403)
  end

  local parts = url.parse_path(ngx.var.uri)
  if #parts > 0 then

    local app_id = tostring(parts[1])
    local app_config_path = string.format("/usr/local/cloud/apps/%s/config.lua", app_id)

    --utils
    local Utils = require('cloud.utils')

    --check for app config
    if not Utils.fileExists( app_config_path ) then
      --no can find
      return ngx.exit(404)
    end

    --open app config
    local app_config_mod = require( app_id..'.config' )

    --defaults
    local app_config =
    {
      key = nil,
      verify_hash = true,
      public = nil,
      reject_all = nil
    }

    --merge config
    app_config = Utils.table_merge( app_config, app_config_mod )

    --app level reject flag
    if app_config.reject_all then
      return ngx.exit(403)
    end

    --if this app is flagged public, carry on
    if app_config.public == true then
      return
    end

    --if we have a matching master key, carry on
    if ngx.ctx.cloud_key == cloud_config.key then
      return
    end

    --check app key
    if ngx.ctx.app_key == app_config.key then
      if app_config.verify_hash then
        --check message hash
        if not auth._checkHash() then
          --hash no matchy
          return ngx.exit(400)
        end
      end

      return
    end

  else --no parts
    return ngx.exit(400)
  end

  --no passes today, sorry.
  return ngx.exit(401)

end

--== Upload auth check
function auth.upload( req )

  local headers = req.get_headers()

  ngx.ctx.host        = headers['Host'] or nil
  ngx.ctx.app_key     = headers["X-Cloud-Key"] or nil
  ngx.ctx.cloud_key   = headers["X-Cloud-Master"] or nil
  ngx.ctx.cloud_hash  = headers['X-Cloud-Hash'] or nil

  --check hash
  if not auth._checkHash() then
    return ngx.exit(401)
  end

  return true
end

return auth
