--[[
Coronium LS - response module
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
--== Don't call this module directly, it belongs to cloud.request
--== xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

local cloud_resp = {}

function cloud_resp.new( response_data, error_data )

  local response = response_data or nil
  local status = response_data.status or nil
  local headers = response_data.headers or {}

  local r =
  {
    response = response,
    body = nil,
    hasBody = false,
    status = status,
    headers = headers,
    hasError = false,
    error = nil
  }

  --parse  it up
  --work with error
  if error_data then
    r.hasError = true
    r.error = error_data
  end

  --work with response
  if r.response then
    if r.response.has_body then
      local body, err = r.response:read_body()

      if err then
        r.hasError = true
        r.error = err
      end

      if body then
        r.body = body
        r.hasBody = true
      end
    end

  end

  return r
end

return cloud_resp
