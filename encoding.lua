--[[
Coronium LS - encoding/decoding module
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
local json_safe = require('cjson.safe')

local function json_encode( content )
  if type(content) == 'userdata' then
    return nil, "Cannot convert userdata."
  end

  if type(content) == 'table' then
    local res, err = json_safe.encode( content )
    if not res then
      return nil, err
    end
    return res, nil
  else
    return tostring( content ), nil
  end
end

local function json_decode( str )
  if type( str ) == 'string' then
    local res, err = json_safe.decode( str )
    if not res then
      return nil, err
    end
    return res, nil
  else
    return tostring( str )
  end
end

local _exports =
{
  decode = {
    uri = ngx.unescape_uri,--encoded
    qstr = ngx.decode_args, -- str
    b64 = ngx.decode_base64, -- b64 str
    json = json_decode
  },
  encode = {
    uri = ngx.escape_uri, --plain
    qstr = ngx.encode_args, --tbl
    b64 = ngx.encode_base64, --str
    json = json_encode
  }
}

return _exports
