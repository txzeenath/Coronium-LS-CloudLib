--[[
Coronium LS - jobs module
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

local jobs = {}

function jobs.run()

  --clear job keys
  local job_dict = ngx.shared.jobs
  job_dict:flush_all()
  job_dict:flush_expired()

  --job path
  local jobs_path = cloud.lib .. '/jobs'

  --pull run Config
  local run_jobs = assert(loadfile(jobs_path..'/run.lua'))()

  --run jobs
  local job_file_path
  for _, job_file in ipairs(run_jobs) do
    job_file_path = jobs_path..'/'..job_file
    assert(loadfile(job_file_path))()
  end
end

return jobs
