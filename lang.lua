--[[
Coronium LS - Language module
Copyright 2016 C.Byerley
Special Thanks: @starcrunch

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
local default_en = require('cloud.lang.en_us')
local lang =
{
  lang_code = 'en_us',
  lang = default_en,
  default_lang_code = 'en_us',
  default_lang = default_en
}

function lang:change(lang_code)
  self.lang_code = lang_code or self.default_lang_code or 'en_us'
  --get lang
  self.lang = nil
  self.lang = require('cloud.lang.'..self.lang_code)

  return self
end

function lang:str(token, end_char, unknown_str)
  if not token then
    return '', nil
  end

  end_char = end_char or '.'
  unknown_str = tostring(unknown_str) or "Unknown."

  if not self.lang then
    --fallback?
    if self.default_lang then
      if self.default_lang[token] then
        return tostring(self.default_lang[token] .. end_char)
      end
    end

    return unknown_str

  else
    --check for lang tokens
    if self.lang[token] then
      return tostring(self.lang[token] .. end_char)
    else
      --fallback?
      if self.default_lang then
        if self.default_lang[token] then
          return tostring(self.default_lang[token] .. end_char)
        end
      end
    end

    return unknown_str
  end
end

return lang
