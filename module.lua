--[[
Coronium LS - module module
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
--== Holds request based methods for routing
--======================================================================--

--== xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--== IMPORTANT!
--== Don't call this module directly, it belongs to nginx
--== xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

local mod = {}

mod.api = function()
  local r = {}

  --======================================================================--
  --== Supported Methods
  r.get = {}
  r.post = {}
  --======================================================================--

  --======================================================================--
  --== Event Hooks
  --== TODO
  r.hook = {}
  --======================================================================--

  return r
end

return mod
