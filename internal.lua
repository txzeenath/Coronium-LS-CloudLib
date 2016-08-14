--[[
Coronium LS - internal module
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

function mod.request(path, args_tbl, method)
  local json = require('cjson')

  --convert method args_tbl
  local body_json = json.encode(args_tbl)
  --set http method
  local method = method or ngx.HTTP_POST

  --read body for safety
  ngx.req.read_body()

  --set up request params
  local params =
  {
    body = tostring(body_json),
    method = method
  }

  --make request
  local res = ngx.location.capture(path, params)

  --check status
  if res.status ~= 200 then
    return { error = "Request Error", errorCode = res.status }
  end

  --check transfer error
  if truncated then
    --error
    return { error = "Request data transfer failed!", errorCode = res.status }
  end

  --try to convert response
  local success, result_tblOrErr = pcall(json.decode, res.body)
  if not success then
    return { error = result_tblOrErr, errorCode = 1 }
  end

  --extract result data
  local data = {}
  if result_tblOrErr.result then
    data = result_tblOrErr.result
  end

  return data, res.header, res.status

end

return mod
