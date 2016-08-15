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

-- function auth._checkHash()
--   local normalized = ngx.ctx.host .. ngx.ctx.project_key .. ngx.var.uri
--   local hash = ngx.md5(normalized)
--
--   if tostring(hash) ~= tostring(ngx.ctx.cloud_hash) then
--     return nil
--   end
--
--   return true
-- end

function auth.request(req)

  local method = req.get_method()

  --all GETs are clear
  if method == cloud.GET then
    return
  end

  local url = require('socket.url')

  local headers = req.get_headers()

  ngx.ctx.host        = headers['Host'] or nil
  ngx.ctx.project_key = headers["X-Project-Key"] or nil

  local parts = url.parse_path(ngx.var.uri)
  if #parts > 0 then

    local project_id = tostring(parts[1])
    local project_config_path = string.format("/home/cloud/projects/%s/config.lua", project_id)

    --utils
    local Utils = require('utils')

    --check for app config
    if not Utils.fileExists( project_config_path ) then
      --no can find
      return ngx.exit(404)
    end

    --open app config
    local project_config_mod = require( project_id..'.config' )

    --defaults
    local project_config =
    {
      key = nil
    }

    --merge config
    project_config = Utils.table_merge( project_config, project_config_mod )

    --if this app is flagged public, carry on
    if project_config.public == true then
      return
    end

    --check project key
    if ngx.ctx.project_key == project_config.key then
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
  ngx.ctx.project_key = headers["X-Project-Key"] or nil

  return true
end

return auth
