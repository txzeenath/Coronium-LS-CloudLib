--[[
Coronium LS - input module
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

--== xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--== IMPORTANT!
--== Don't call this module directly, it belongs to nginx
--== xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

local mod = {}

function mod.request(req)

  local cjson = require('cjson')

  local json_enc = cjson.encode
  local json_dec = cjson.decode

  local body = nil
  body = req.get_body_data()
  if not body then
    req.read_body()
    body = req.get_body_data()
    if not body then
      body = req.get_body_file()
    end
  end

  local method = req.get_method()
  local headers = req.get_headers()
  local path = ngx.var.document_uri
  local qstr = req.get_uri_args()

  --check HTTPXMLRequest
  ngx.ctx.isAjax = false
  if headers["XMLHttpRequest"] then
    ngx.ctx.isAjax = true
  end

  ngx.ctx.key = headers["X-Cloud-Key"] or nil

  ngx.ctx.method = string.lower(method)
  ngx.ctx.headers = headers
  ngx.ctx.path = path
  ngx.ctx.query = qstr
  ngx.ctx.body = body
  --==============================================================--
  --== Utils
  --==============================================================--
  local function split(inputstr, sep)
    if sep == nil then
      sep = "%s"
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
      t[i] = str
      i = i + 1
    end
    return t
  end
  --==============================================================--
  --== Path Input
  --==============================================================--
  local parts = split( path, "/" )

  local func_parts = {}
  for p=1, #parts do
    table.insert(func_parts, parts[p])
  end
  local func_path = table.concat(func_parts, "/")

  ngx.ctx.func_path = func_path
  ngx.ctx.func_parts = func_parts
  --==============================================================--
  --== Body / Query Args Input
  --==============================================================--
  local input_data
  if ngx.ctx.body then
    input_data = json_dec(ngx.ctx.body)
  elseif ngx.ctx.query then
    input_data = ngx.ctx.query
  end
  --==============================================================--
  --== Process API
  --==============================================================--
  local module_name = ngx.ctx.func_parts[1]
  local func_name = ngx.ctx.func_parts[2]

  ngx.ctx.func_name = func_name

  ngx.var.template_root = '/usr/local/cloud/apps/'..module_name..'/tpl'

  local api_path = string.format("%s.api", module_name )

  local api = require( api_path )

  local func_params = {}
  for p=3, #ngx.ctx.func_parts do
    table.insert( func_params, ngx.ctx.func_parts[p] )
  end

  --== Figure out what to call or get
  local function processOutput( output, content_type, headers )
    content_type = content_type or 'application/json'
    headers = headers or {}

    ngx.header["Content-Type"] = content_type
    ngx.header["Accept"] = 'application/json'
    ngx.header['Server'] = 'CoroniumLS/1.0b'

    for i, h in pairs(headers) do
      ngx.header[ tostring(i) ] = tostring(h);
    end

    local output_data

    if content_type == 'application/json' then

      local ok, res = pcall(json_enc, output)
      if ok then
        output_data = json_enc({ result = output })
      else
        output_data = json_enc({ error = 99, result = res })
      end
    else
      output_data = output
    end

    ngx.say( output_data )
    return ngx.exit(ngx.HTTP_OK)
  end

  local api_func
  if ( api[ngx.ctx.method][ngx.ctx.func_name] ) then
    api_func = api[ngx.ctx.method][ngx.ctx.func_name]

    --if its a function, run it
    if type( api_func ) == 'function' then
      processOutput( api_func(input_data, ngx.ctx.isAjax, ngx.ctx.headers, ngx.ctx.method) )
    else
      ngx.exit(ngx.HTTP_BAD_REQUEST)
    end

  else
    ngx.exit(ngx.HTTP_METHOD_NOT_IMPLEMENTED)
  end

  ngx.exit(ngx.HTTP_METHOD_NOT_IMPLEMENTED)

end

return mod
