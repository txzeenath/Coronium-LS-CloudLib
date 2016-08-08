--[[
Coronium LS - template module
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

function mod.new( withMarkdown )
  local template = require('resty.template')
  template.caching( false )

  if withMarkdown then
    template.markdown = require('resty.hoedown')
  end

  return template
end

function mod.render( tpl_file_name, tpl_values_tbl, withMarkdown )

  if tpl_file_name == nil then
    return nil, "Template file name is missing"
  end

  if (tpl_values_tbl == nil) or (type(tpl_values_tbl) ~= 'table') then
    return nil, "Values table is missing or malformed"
  end

  local template = require('resty.template')
  template.caching( false )

  local str = template.compile( tpl_file_name )( tpl_values_tbl )

  return str, nil

end

return mod
