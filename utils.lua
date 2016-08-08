--[[
Coronium LS - utils module
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

local mod = {}

mod.uuid = function()
  --use resty module
  return require('resty.uuid').generate()
end

mod.split = function(inputstr, sep)
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

mod.trim = function( str )
  return (string.gsub(str, "^%s*(.-)%s*$", "%1"))
end

mod.strf = string.format

--== JSONable table - .toJson()
mod.jtable = function()
  local t = {}
  local _mt =
  {
    toJson = function()
      return json.encode( t )
    end
  }
  _mt.__index = _mt
  setmetatable( t, _mt )
  return t
end

--==Check if a file exists
mod.fileExists = function(filepath)
  local io = require('io')
  if not io.open(filepath) then
    return nil
  end
  return true
end

--==Merge "flat" tables, with optional defaults (or {}|nil)
--==Last value wins. Good for configs.
mod.table_merge = function( default_tbl_vals, ... )
  local merge_tbls_arr = { ... }
  local default_tbl_vals = default_tbl_vals or {}

  local tbl = default_tbl_vals

  for _, tbl_vals in ipairs( merge_tbls_arr ) do
    for name, val in pairs( tbl_vals ) do
      tbl[name] = val
    end
  end

  return tbl
end

--==PrettyPrint table
mod.pp = function( tbl, indent )
  if not tbl and type( tbl ) ~= 'table' then
    return nil, "Please provide a valid table"
  end

  local names = {}
  if not indent then indent = "" end
  for n,g in pairs(t) do
      table.insert(names,n)
  end
  table.sort(names)
  for i,n in pairs(names) do
      local v = t[n]
      if type(v) == "table" then
          if(v==t) then -- prevent endless loop if table contains reference to itself
              cloud.log(indent..tostring(n)..": <-")
          else
              cloud.log(indent..tostring(n)..":")
              pp(v,indent.."   ")
          end
      else
          if type(v) == "function" then
              cloud.log(indent..tostring(n).."()")
          else
              cloud.log(indent..tostring(n)..": "..tostring(v))
          end
      end
  end
end

return mod
