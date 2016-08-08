--[[
Coronium LS - async module
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

--======================================================================--
-- Runs in request context (ngx.thread)
--======================================================================--
local async = {}

function async.start( func, ... )
  local callback = func
  local args = ...

  local ngx_thread = ngx.thread

  local _async = ngx_thread.spawn( callback, args )
  if not _async then
    callback( nil, "Async could not run" )
    return
  end

  return _async, nil

end

function async.wait( asyncs )
  local ngx_thread = ngx.thread
  for i=1, #asyncs do
    local ok, res = ngx_thread.wait( asyncs[i] )

    if not ok then
      return nil, "Failed to run: "..res
    else
      return res, nil
    end
  end
end

function async.stop( _async )
  local ngx_thread = ngx.thread
  local ok, err = ngx_thread.kill( _async )
  if not ok then
    return nil, err
  end
  return ok, nil
end

return async
