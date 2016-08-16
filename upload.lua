--[[
Coronium LS - upload module
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

function mod.file(req)

  local os = require('os')
  local io = require('io')
  local url = require('socket.url')

  local headers = req.get_headers()

  local src_file_name = headers["X-Cloud-File"] or nil
  if not src_file_name then
    return ngx.exit(401)
  end
  local src_file_dir = headers["X-Cloud-Dir"] or nil

  local files_dir = '/home/cloud/files'

  local sock, err = req.socket()
  local data, err, partial = sock:receive('*a')
  if not data then
    ngx.log(ngx.ERR, "No data stream "..err)
    return ngx.exit(500)
  end

  local file_destination, msg

  if src_file_dir ~= nil then
    file_destination = files_dir .. '/' .. src_file_dir
    os.execute( 'mkdir -p ' .. file_destination )
    os.execute( 'chmod -R 0775 ' .. file_destination )
  else
    src_file_dir = '/'
    file_destination = files_dir
    os.execute( 'mkdir -p ' .. files_dir )
    os.execute( 'chmod -R 0775 ' .. files_dir )
  end

  file_destination = file_destination .. '/' .. src_file_name

  if os.execute( 'touch '..file_destination ) ~= 0 then
    msg = { result = { error = "Could not create the file!" } }
  else

    if partial ~= nil then
      data = data .. partial
    end

    os.execute( 'chmod 0664 ' .. file_destination )

    local f = io.open( file_destination, 'wb' )
    f:write( data )
    f:close()

    msg = { result = { baseDirectory = src_file_dir, filename = src_file_name } }
  end

  data = nil

  ngx.say( cloud.encode.json( msg ) )

  return ngx.exit(ngx.HTTP_OK)

end

return mod
