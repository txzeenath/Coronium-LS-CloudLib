--[[
Coronium LS - mysql module
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

local _M = {}

local function _connect( db_connection_table )

    if not db_connection_table then
      return nil, "Connection table required"
    else

      local ct = db_connection_table

      local db_name = ct.database
      local db_user = ct.user or "cloud"
      local db_password = ct.password or "cloudadmin"
      local db_host = ct.host or "127.0.0.1"
      local db_port = ct.port or 3306

      local mysql = require( "resty.mysql" )
      local db, err = mysql:new()

      if not db then
        return nil, err
      else

        db:set_timeout( 2000 )

        local ok, err = db:connect{
            host = db_host,
            port = db_port,
            database = db_name,
            user = db_user,
            password = db_password }

        if not ok then
          return nil, err
        end

        return db, nil --connected

      end
    end

    return nil, "Could not connect!"
end

function _M.query( connect_table, query )

  local db, err = _connect( connect_table )
  if not db then
    return nil, err
  end

  --== Initial query
  local res, err, errcode = db:query( query )
  if not res then
    return nil, err, errcode
  end

  local t = {}
  table.insert( t, res )

  while err == "again" do
    res, err, errcode = db:read_result()
    if not res then --== Error
      return nil, err, errcode
    end

    table.insert( t, res )
  end

  local r
  if #t == 1 then
    r = table.remove( t )
  else
    r = t
  end

  -- put it into the connection pool of size 20,
  -- with 30 seconds max idle timeout
  local ok, err = db:set_keepalive( 15000, 5 )
  if not ok then
      cloud.log( err ) --log it
      db:close() --force close
  end

  return r, nil
end

--==============================================================--
--== MySQL Safe String
--==============================================================--
function _M.string( unwashed_str )
  return ngx.quote_sql_str( unwashed_str )
end

--==============================================================--
--== MySQL Databag
--==============================================================--
function _M.databag(connect_table)
  local bag =
  {
    connect_table = connect_table,
    tableName = nil,
    columns = nil,
    values = nil,
    where = nil,
    orderby = nil,
    limit = nil,
    distinct = nil
  }

  function bag:cleanbag()

    self.tableName = nil
    self.columns = nil
    self.values = nil
    self.where = nil
    self.orderby = nil
    self.limit = nil
    self.distinct = nil

  end

  --[[
  select schema
  local result, err = bag:select({
    tableName = "tableName",
    columns = {'col1','col2',...},
    where = 'somearg=someval',
    limit = 20,
    distinct = true,
    orderby = {
      col1 = cloud.ASCENDING
      col2 = cloud.DESCENDING
    }
  })
  ]]
  function bag:select( select_tbl )
    if not select_tbl.tableName then
      return nil, "Table name is missing"
    end

    self:cleanbag()

    --build query
    self.tableName  = select_tbl.tableName

    if not select_tbl.columns then
      self.columns = '*'
    else
      if type(select_tbl.columns) == 'table' then
        self.columns = table.concat(select_tbl.columns, ', ')
      end
    end

    self.where      = select_tbl.where or nil
    self.orderby    = select_tbl.orderby or nil
    self.limit      = select_tbl.limit or nil
    self.distinct   = select_tbl.distinct or nil

    local qt = {}

    if self.distinct then
      table.insert(qt, cloud.sf("SELECT %s FROM %s", self.columns, self.tableName))
    else

    end

    local select_str = "SELECT %s FROM %s"
    if self.distinct then
      select_str = "SELECT DISTINCT %s FROM %s"
    end
    table.insert(qt, cloud.sf(select_str, self.columns, self.tableName))

    if self.where then
      if string.find(self.where, "WHERE") ~= nil then
        return nil, "Do not include the WHERE clause command in the string"
      end

      table.insert(qt, cloud.sf("WHERE %s", self.where))
    end

    if self.orderby then
      local orderString = ""
      for i,v in pairs(self.orderby) do
        if string.len(orderString) > 0 then orderString = orderString.."," end
		orderString = orderString..i.." "..v
      end
      table.insert(qt, cloud.sf("ORDER BY %s", orderString))
    end

    if self.limit then
      table.insert(qt, cloud.sf("LIMIT %d", self.limit))
    end

    local qstr = table.concat(qt, ' ')
    return _M.query(connect_table, qstr)

  end

  function bag:insert(insert_tbl)

    self:cleanbag()

    if not insert_tbl.tableName then
      return nil, "Table name required"
    end

    if not insert_tbl.columns then
      return nil, "Fields are required"
    end

    if not insert_tbl.values then
      return nil, "Values are required"
    end

    if #insert_tbl.columns ~= #insert_tbl.values then
      return nil, "Fields and Values count mismatch"
    end

    self.tableName  = insert_tbl.tableName

    self.columns    = table.concat(insert_tbl.columns, ', ')

    self.values = {}
    for _, val in ipairs(insert_tbl.values) do
      if type(val) == 'string' then
        val = cloud.mysql.string(val)
      end

      table.insert(self.values, val);
    end

    self.values = table.concat(self.values, ', ')

    local query = cloud.sf("INSERT INTO %s (%s) VALUES (%s);", self.tableName, self.columns, self.values)

    return _M.query(self.connect_table, query)

  end

  function bag:delete(delete_tbl)

    if not delete_tbl.tableName then
      return nil, "Table name required"
    end

    self:cleanbag()

    local qt = {}
    table.insert(qt, cloud.sf("DELETE FROM %s", self.tableName))

    if delete_tbl.where then
      self.where = delete_tbl.where
      table.insert(qt, cloud.sf("WHERE %s", self.where))
    else
      return nil, "WHERE clause missing"
    end

    local query = table.concat(qt, ' ')
    return _M.query(self.connect_table, query)

  end

  function bag:update(update_tbl)

    self:cleanbag()

    if not update_tbl.tableName then
      return nil, "Table name required"
    end
    self.tableName = update_tbl.tableName

    local qt = {}
    table.insert(qt, cloud.sf("UPDATE %s", self.tableName))

    if not update_tbl.values then
      return nil, "Values missing"
    end
    self.values = {}
    for name, val in pairs(update_tbl.values) do
      if type(val) == 'string' then
        val = cloud.mysql.string(val)
      end
      table.insert(self.values, name..'='..val)
    end
    table.insert(qt, cloud.sf("SET %s", table.concat(self.values, ', ')))

    if update_tbl.where then
      self.where = update_tbl.where
      table.insert(qt, cloud.sf("WHERE %s", self.where))
    end

    local query = table.concat(qt, ' ')
    return _M.query(self.connect_table, query)

  end

  return bag
end

return _M
