--[[
Coronium LS - Mongo module
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
local Mongo = {}

function Mongo.new( host, port )
  local mongol = require( 'resty.mongol' )
  local mongo_obj = mongol:new() --init mongo module

  host = host or '127.0.0.1'
  port = port or 27017

  local ok, err = mongo_obj:connect( host, port )
  if not ok then
    return nil, err
  end

  local obj_cmds = { }

  local obj_mt = setmetatable( {
    host = host,
    port = port,
    db = nil,
    timeout_ms = 30000,
    keep_alive_ms = 30000,
    keep_alive_pool = 10,
    mongo = mongo_obj
  }, { __index = obj_cmds } )

  --helper for mongo num to bool
  local function bool2num( bool )
    if type(bool) == 'boolean' then
      if bool == true then
        return 1
      else
        return 0
      end
    end

    return bool, nil
  end

  -- helper for cleaning/replacing BSON values that will
  -- fail on a JSON encode.
  local function parseDoc( doc, hide_meta )
    if not doc._id then return nil,doc end
    
    if doc then
      if not hide_meta then
        doc._ts   = doc._id:get_ts() --timestamp
        doc._id   = doc._id:tostring() --id must be pulled last, clears BSON
      else
        doc._id = nil --clear problematic BSON `userdata`
      end

      return doc, nil
    end

    return nil, "Could not parse document."
  end

  --==============================================================--
  --== TODO
  --==============================================================--
  function obj_cmds:js( mongo_js_file )   --== NOT TESTED
    local status = os.execute( 'mongo '..mongo_js_file )

    return status, nil
  end
  --==============================================================--

  function obj_cmds:databases()
    local dbs = self.mongo:databases()
    if not dbs then

      return nil, "Could not load databases."
    end

    return dbs, nil
  end

  function obj_cmds:close()
    return self.mongo:close()
  end

  function obj_cmds:set_timeout( ms )
    local ms = ms or self.timeout_ms or 30000
    local ok, err = self.mongo:set_timeout( ms )
    if not ok then
      return nil, err
    end
    self.timeout_ms = ms

    return true, nil
  end

  function obj_cmds:get_timeout()
    return self.timeout_ms, nil
  end

  function obj_cmds:set_keepalive( ms, pool_size )
    local ms = ms or self.keep_alive_ms or 30000
    local pool_size = pool_size or self.keep_alive_pool or 10

    local ok, err = self.mongo:set_keepalive( ms, pool_size )
    if not ok then
      return nil, err
    end
    self.keep_alive_ms = ms
    self.keep_alive_pool = pool_size

    return true, nil
  end

  function obj_cmds:get_keepalive_ms()
    return self.keep_alive_ms, nil
  end

  function obj_cmds:get_keepalive_pool()
    return self.keep_alive_pool, nil
  end

  function obj_cmds:use_db( db_name )
    self.db = self.mongo:new_db_handle( db_name )

    local parseDoc = parseDoc
    local coll_tools_mt = setmetatable(
    {
      db = self.db,
      coll = nil
    },
    {
      __index = function( t, k )
        t['coll'] = k

        local collection = self.db:get_col( k )
        local m =
        {
          collection = collection
        }

        function m:aggregate( pipeline )
          assert(pipeline, "The pipeline parameter is missing.")
          local n, err = self.collection:aggregate( pipeline )
          if not n then
            return nil, err
          end
          return n, nil
        end

        function m:count( query )
          local count = self.collection:count( query )
          if not count then
            return nil, "Could not get count query."
          end
          return count, nil
        end

        function m:insert(docs, cont_on_err, safe)
          assert(docs, "No documents included.")
          local ok, err = self.collection:insert(docs, cont_on_err, safe)
          if not ok then
            return nil, err
          end
          return true, nil
        end

        function m:insert_one(doc)
          assert(doc, "No document included.")
          local ok, err = self.collection:insert({ doc })
          if not ok then
            return nil, err
          end
          return true, nil
        end

        function m:update(selector, update, upsert, multi_update, replace, safe)
          assert(selector, "An update selector is required.")
          assert(update, "An update table is required.")

          local upsert = upsert or false
          local multi_update = multi_update or false
          local safe = safe or false
          local replace = replace or false
          if not replace then 
             update = {['$set'] = update}
          end

          local rows, err = self.collection:update(selector, update, bool2num(upsert), bool2num(multi_update), safe)
          if not rows then
            return nil, err
          end
          return rows, nil
        end

        function m:batch_update(queries_tbl, ordered, write_concern)
          assert(queries_tbl, "A table array of queries is required.")

          local doc, err = self.collection:update_all(queries_tbl, ordered, write_concern)
          if not doc then
            return nil, err
          end
          return doc, nil
        end

        function m:delete(selector, single, safe)
          assert(selector, "Delete selector is missing.")
          if single == nil then single = true end
          single = bool2num( single )

          local rows, err = self.collection:delete(selector, single, safe)
          if not rows then
            return nil, err
          end
          return rows, nil
        end

        function m:find_one(query, fld_filter)
          assert(query, "Query parameter is missing.")

          local res, err = self.collection:find_one(query, fld_filter)

          if not res then
            return nil, "Could not find document."
          end

          res,err = parseDoc( res )

          return res, err
        end

        function m:find(query, fld_filter, num_each_query)
          assert(query, "Query parameter is missing.")

          local cursor = self.collection:find(query, fld_filter, num_each_query)
          if not cursor then
            return nil, "Could not open cursor."
          end

          local c =
          {
            cursor = cursor
          }

          function c:next()
            local idx, doc = self.cursor:next()
            doc = parseDoc( doc )
            if not idx then
              return nil, "No index found."
            end
            return idx, doc
          end

          function c:skip(amount)
            return self.cursor:skip(amount)
          end

          function c:limit(amount)
            return self.cursor:limit(amount)
          end

          function c:sort(sort_filter, sort_tmp_arr_len)
            sort_tmp_arr_len = sort_tmp_arr_len or 1000
            return self.cursor:sort(sort_filter, sort_tmp_arr_len)
          end

          function c:get_pairs()
            local p = {}
            for idx, item in self.cursor:pairs() do
              table.insert(p, idx, item)
            end
            return p
          end

          return c, nil
        end

        --pager
        function m:pager(query, start_page, per_page, fld_filter, sort_filter, sort_tmp_arr_len)
          start_page = start_page or 1
          per_page = per_page or 10
          sort_tmp_arr_len = sort_tmp_arr_len or per_page or 1000

          local cursor, err = self.collection:find(query, fld_filter, per_page)
          if not cursor then
            return nil, err
          end

          if sort_filter then
            cursor:sort(sort_filter, sort_tmp_arr_len)
          end

          if per_page then
            cursor:limit(per_page)
          end

          if start_page then
            local real_page = per_page * (start_page - 1)
            cursor:skip(real_page)
          end

          local documents = {}
          for idx, doc in cursor:pairs() do
            doc = parseDoc( doc )
            documents[idx] = doc
          end
          if not next(documents) then documents = nil end --Don't return an empty table
          return documents, nil

        end

        function m:drop(confirm)
          assert(confirm, "You must pass a `true` boolean to confirm a Collection drop.")
          local ok, err = self.collection:drop()
          if not ok then
            return nil, err
          end
          return ok, nil
        end

        return m
      end
    })

    return coll_tools_mt
  end

  return obj_mt

end

return Mongo
