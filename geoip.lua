--[[
Coronium LS - geoip module
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
local geoip =
{
  getCountryCode = function()
    return ngx.var.geoip_country_code
  end,
  getCountryCode3 = function()
    return ngx.var.geoip_country_code3
  end,
  getCountryName = function()
    return ngx.var.geoip_country_name
  end,
  getRegion = function()
    return ngx.var.geoip_region
  end,
  getRegionName = function()
    return ngx.var.geoip_region_name
  end,
  getCity = function()
    return ngx.var.geoip_city
  end,
  getPostalCode = function()
    return ngx.var.geoip_postal_code
  end,
  getCityContinentCode = function()
    return ngx.var.geoip_city_continent_code
  end,
  getLatitude = function()
    return ngx.var.geoip_latitude
  end,
  getLongitude = function()
    return ngx.var.geoip_longitude
  end
}

return geoip
