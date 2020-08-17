--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

--[[
   list will keep only one value instance,
   for value <-> node mapping
]]

local _M = {}
_M.__index = _M

local function _add_maps(self, node, value)
   self._vnmap[value] = node
   self._nvmap[node] = value
   self._count = self._count + 1
   return value
end

local function _remove_node(self, node)
   local value = self._nvmap[node]
   self._nvmap[node] = nil
   self._vnmap[value] = nil
   if self._root.head == node then
      self._root.head = node.next
   end
   if self._root.tail == node then
      self._root.tail = node.prev
   end
   if node.prev then
      node.prev.next = node.next
   end
   if node.next then
      node.next.prev = node.prev
   end
   self._count = self._count - 1
   return value
end


-- public interface
--

function _M:first()
   if self._count <= 0 then
      return nil
   end
   return self._nvmap[self._root.head]
end

function _M:last()
   if self._count <= 0 then
      return nil
   end
   return self._nvmap[self._root.tail]
end

function _M:pushf(value)
   if value == nil then
      return nil
   end
   local node = self._vnmap[value]
   if node then
      _remove_node(self, node)
   end
   node = {}
   node.next = self._root.head
   if self._root.head then
      self._root.head.prev = node
   else
      self._root.tail = node
   end
   self._root.head = node
   return _add_maps(self, node, value)
end

function _M:pushl(value)
   if value == nil then
      return nil
   end
   local node = self._vnmap[value]
   if node then
      _remove_node(self, node)
   end
   node = {}
   node.prev = self._root.tail
   if self._root.tail then
      self._root.tail.next = node      
   else
      self._root.head = node
   end
   self._root.tail = node   
   return _add_maps(self, node, value)
end

function _M:popf()
   if self._count <= 0 then
      return nil
   end
   return _remove_node(self, self._root.head)
end

function _M:popl()
   if self._count <= 0 then
      return nil
   end
   return _remove_node(self, self._root.tail)
end

function _M:remove(value)
   if value == nil then
      return nil
   end
   local node = self._vnmap[value]
   if node then
      return _remove_node(self, node)
   end
end

function _M:range(from, to)
   from = from or 1
   to = to or self._count
   if self._count <= 0 or from < 1 or from > self._count or from > to then
      return {}
   end
   to = math.min(self._count, to)
   local range = {}
   local idx = 1
   local node = self._root.head
   repeat
      local nn = node.next
      if idx >= from and idx <= to then
         range[#range + 1] = self._nvmap[node]
      end
      node = nn
      idx = idx + 1
   until (node == nil) or (idx > to)
   return range
end

function _M:walk()
   if self._count <= 0 then
      return function() return nil end
   end
   local idx = 1
   local node = self._root.head
   return function()
      if node then
         local i = idx
         local n = node
         idx = idx + 1
         node = node.next
         return i, self._nvmap[n]
      else
         return nil
      end
   end
end

function _M:count()
   return self._count
end

-- constructor
local function _new()
   local ins = {}
   setmetatable(ins, _M)
   ins._root = {}
   ins._count = 0
   ins._vnmap = {}              -- value to node
   ins._nvmap = {}              -- node to value
   return ins
end

return {
   new = _new
}
