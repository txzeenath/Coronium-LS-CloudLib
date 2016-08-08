--[[
Coronium LS - job module
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
-- Runs outside of request context (ngx.timer)
-- Use to build job files for /jobs directory
--======================================================================--
local job = {}

function job.run( delay, interval, loop, func, ... )

  local function newIdx()
    return cloud.uuid()
  end

  local ngx_timer = ngx.timer
  local job_dict = ngx.shared.jobs

  local delay = delay or 0 --delay before first run
  local interval = interval or 0 --delay between runs
  local loop = loop or 0 --loops -1 = forever
  local callback = func
  local args = ...

  local _callback
  local log = cloud.log
  local jobid = newIdx()

  _callback = function( premature, ... )

    if premature then
      job_dict:delete(jobid)
      callback( nil, "Job abandoned!" )
      return
    end

    --check if this timer has been aborted
    if not job_dict:get(jobid) then
      callback( nil, "Job aborted" )
      return
    end

    --check loop
    if loop ~= 0 then
      callback( true, args )

      local ok, err = ngx_timer.at( interval, _callback, args )
      if not ok then
        callback( nil, err )
        return
      end

      if loop > 0 then
        loop = loop - 1
      end

    else
      --clean
      log(jobid..' Done')
      job_dict:delete(jobid)
      return
    end
  end

  --add job ref
  job_dict:add(jobid, true)

  --check for start delay
  if delay == 0 then
    delay = 1 --tiny buffer
  end

  local ok, err = ngx_timer.at( delay, _callback, args )
  if not ok then
    callback( nil, err )
    return
  end

  return jobid
end

function job.stop( jobid )
  local job_dict = ngx.shared.jobs

  if not job_dict:get(jobid) then
    return nil, "Job ID not found"
  end

  job_dict:delete(jobid)
  return true, nil
end

return job
