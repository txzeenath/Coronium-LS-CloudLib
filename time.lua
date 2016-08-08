--[[
Coronium LS - time module
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

local time_obj = {}

function time_obj.epoch( force_update )
  return ngx.time()
end

function time_obj.utc( force_update )
  return ngx.utctime()
end

function time_obj.localTime( force_update )
  return ngx.localtime()
end

function time_obj.cookieTime( sec, force_update )
  if force_update then
    ngx.update_time()
  end
  return ngx.cookie_time( sec )
end

function time_obj.httpTime( sec, force_update )
  if force_update then
    ngx.update_time()
  end
  return ngx.http_time( sec )
end

function time_obj.now( force_update )
  if force_update then
    ngx.update_time()
  end
  return ngx.now()
end

function time_obj.today( force_update )
  if force_update then
    ngx.update_time()
  end
  return ngx.today()
end

function time_obj.update() --make cache current
  ngx.update_time()
  return ngx.now()
end


return time_obj
