-- this module deals with the 'list of lockboxes' object


function InitLockboxes()
lockboxes={}

lockboxes.path=function(self, name)
return process.getenv("HOME") .. "/.treasury/" .. name ..".lb"
end



lockboxes.add=function(self, path)
local item, str

str=filesys.basename(path)
pos=string.find(str, '%.')
if pos > 1 then str=string.sub(str, 1, pos-1) end

item=LockboxCreate(str)
table.insert(self.items, item)

return item
end



lockboxes.load=function(self)
local glob, str, item

self.items={}
glob=filesys.GLOB(self:path("*"))
str=glob:next()
while str ~= nil
do
self:add(str)
str=glob:next()
end

end



lockboxes.new=function(self, name, password, hint)
local path, S, item

path=self:path(name)
item=self:add(path)
item.password=password
item.passhint=hint
item:save()

sync:update(item)

return item
end


lockboxes.first=function(self)
self.pos=1
return self.items[1]
end


lockboxes.next=function(self)
if self.pos==nil then return self:first() end

self.pos=self.pos + 1

return self.items[self.pos]
end



lockboxes.list=function(self)
local glob, item
local boxes={}


glob=filesys.GLOB(self:path("*"))
item=glob:next()
while item ~= nil
do
table.insert(boxes, filesys.filename(item))
item=glob:next()
end

return boxes
end


lockboxes.find=function(self, name)
local key, item

for key,item in ipairs(self.items)
do
if item.name==name then return item end
end

--if we get here we didn't find it, try syncing
print("'"..name.."' does not exist... checking for sync files")
item=LockboxCreate(name)
if sync:update(item) == true then return item end
return nil
end


lockboxes.deposit=function(self, boxname, key, value, notes)
local box

box=self:find(boxname)
if box == nil then box=self:new(boxname) end

if box:load() == true
then
box:add(key, value, notes)
box:save()
return true

end

return false
end


lockboxes.read=function(self, boxname)
local box
local str=""

box=self:find(boxname)
if box ~= nil then str=box:read() end

return str
end


lockboxes.sync=function(self, path)
local tmp, box, name

tmp=SyncOpenImport(path)
if tmp == nil then return false end

box=lockboxes:find(tmp.name)
if box == nil
then
 box=LockboxCreate(tmp.name, nil, tmp.password, tmp.passhint)
else 
  if box:load() == false then return false end
end

if box ~= nil
then
box:update(tmp)
box:save()
ScrubFile(path)
filesys.unlink(path)
return true
end

return false
end


lockboxes.sync_push=function(self)
local i, item

for i,item in ipairs(self.items)
do
sync:send(item)
end

end


lockboxes:load()

return lockboxes
end
