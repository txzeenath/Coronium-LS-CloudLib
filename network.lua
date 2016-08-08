--[[
Coronium LS - network module
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
local network = {}

function network.new(host, port)
  local c
  --push as magic table?
  if type(host) == 'table' then
    c = host
  else
    c =
    {
      host = host or "127.0.0.1",
      port = port or 80,
      method = "GET",
      headers =
      {
        ['Content-Type'] = 'application/json',
        ['Accept'] = 'application/json;plain/text'
      },
      body = nil,
      timeout = 500,
      chunk_size = 8192,
      ssl_verify = false,
      keep_alive_ms = 30000, --30 secs
      keep_alive_poolsize = 3
    }
  end

  function c:host(host)
    if not host then
      return self.host
    end

    self.host = host
    return self
  end

  function c:port(port)
    if not port then
      return self.port
    end

    self.port = port
    return self
  end

  function c:path(path_str)
    if not path_str then
      return self.path
    end

    self.path = path_str
    return self
  end

  function c:header(name, value)
    if not value then
      return self:headers()[name]
    end

    self:headers()[name] = value
    return self
  end

  function c:headers(headers)
    if not headers then
      return self.headers
    end

    self.headers = headers
    return self
  end

  function c:method(method)
    if not method then
      return self.method
    end

    self.method = method
    return self
  end

  function c:timeout(time)
    if not time then
      return self.timeout
    end

    self.timeout = time
    return self
  end

  function c:keep_alive(ms, poolsize)
    if not ms and not poolsize then
      return self.keep_alive_ms, self.keep_alive_poolsize
    end

    self.keep_alive_ms = ms
    self.keep_alive_poolsize = poolsize

    return self
  end

  function c:chunk_size(size)
    if not size then
      return self.chunk_size
    end

    self.chunk_size = size
    return self
  end

  function c:ssl_verify(ssl_flag)
    if not ssl_flag then
      return self.ssl_verify
    end

    self.ssl_verify = flag
    return self
  end

  function c:body(body, toJson)
    if toJson and type(body) == 'table' then
      body = cloud.jsonify(body)
    else
      if not body then
        return nil, "No body found!"
      end
    end

    self.body = body
    return self
  end

  function c:response(result)
    local r =
    {
      status = result.status,
      reason = result.reason,
      headers = result.headers,
      has_body = result.has_body,
      body_reader = result.body_reader,
      read_body = result.read_body,
      read_trailers = result.read_trailers
    }
    return r
  end

  function c:result()
    local http = require('resty.http')
    local httpc = http.new()

    httpc:set_timeout(self:timeout())
    httpc:connect(self:host(), self:port())

    local result, err = httpc:request({
      method = self:method(),
      path = self:path(),
      headers = self:headers(),
      body = self:body(),
      ssl_verify = self:ssl_verify()
    })

    if not result then
      return nil, err
    end

    local response = self:response(result)

    --body reader
    local reader = response.body_reader
    local buffy = {}
    repeat
      local chunk, err = reader(self:chunk_size())
      if err then
        return nil, err
      end

      if chunk then
        table.insert(buffy, chunk)
      end
    until not chunk

    local full_body = table.concat(buffy)
    cloud.log(full_body)

    local ms, pool = self:keep_alive()
    local success, err = httpc:set_keepalive(ms, pool)
    if err and success == 2 then
      httpc:close()
    end

    return full_body, nil
  end

  return c
end

return network
