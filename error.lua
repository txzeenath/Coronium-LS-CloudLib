--[[
Coronium LS - error module
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

local err = {}

function err.new( err_str, err_status, err_info_tbl )
  local e =
  {
    hasError = true,
    error = err_str or "Unknown",
    status = err_status or 0,
    info = err_info_tbl or nil
  }
  return e
end

return err
