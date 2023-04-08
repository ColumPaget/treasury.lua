function SyncInit()
local sync={}


sync.load=function(self, path, password)
local tmp

tmp=LockboxCreate("", path, password)
if tmp==nil then return nil end
if tmp:examine() == false then return nil end
if strutil.strlen(tmp.name) == 0 then return nil end

if tmp.password == nil then
tmp.password=QueryPassword("Enter Password for import file: ", tmp.passhint)
end

tmp.suppress_errors=true
if tmp:load_items() == false then return nil end

return tmp
end




sync.import_item=function(self, existing, new) 
local exist_time, new_time

exist_time=time.tosecs("%Y/%m/%dT%H:%M:%S", existing.updated)
new_time=time.tosecs("%Y/%m/%dT%H:%M:%S", new.updated)

if new_time > exist_time
then
existing.updated=new.updated
existing.value=new.value
end

end


sync.import=function(self, box, other)
local key, item

for key,item in pairs(other.items)
do
	existing=box.items[key]
	if existing ~= nil then self:import_item(existing, item) 
	else box.items[key]=item
	end
end


end



sync.update=function(self, box)
local path, tmp
local changed=false

path=process.getenv("HOME") .. "/.treasury/sync_in/*-"..box.name..".sync"
files=filesys.GLOB(path)

path=files:next()
while path ~= nil
do
tmp=self:load(path, box.password)
if tmp ~= nil
then 
  if hosts:check_version(tmp.machine_id, tmp.name, tmp.version)==true
  then 
    print("sync importing..." ..path)
    self:import(box, tmp)
    if strutil.strlen(box.password) == 0 then box.password=tmp.password end
    if strutil.strlen(box.passhint) == 0 then box.passhint=tmp.passhint end
    changed=true
  end
  tmp:destroy()
end

path=files:next()
end

if changed==true then box:save() end
return changed
end


sync.send=function(self, box)
local dst_path, final_path

dst_path=process.getenv("HOME") .. "/.treasury/sync_out/" .. sys.hostname() .. "-" .. box.name ..".tmp"
filesys.mkdirPath(dst_path)
filesys.copy(box.path, dst_path)
final_path=process.getenv("HOME") .. "/.treasury/sync_out/" .. sys.hostname() .. "-" .. box.name ..".sync"
filesys.rename(dst_path, final_path)

end


return sync
end
