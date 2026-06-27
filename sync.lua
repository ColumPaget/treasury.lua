function SyncInit()
local sync={}


sync.load=function(self, path, password)
local tmp

if GlobalDebug == true then io.stderr:write("sync:load '".. tostring(path) .. "' with password='".. tostring(password) .."'\n") end

tmp=LockboxCreate("", path, password)
if tmp==nil then return nil end
if tmp:examine() == false then return nil end
if strutil.strlen(tmp.name) == 0 then return nil end

tmp.suppress_errors=true
if tmp:load_items() == false
then 
  tmp.password=ui:ask_password("Enter Password for sync file '"..filesys.basename(path).."': ", tmp.passhint)
  if tmp:load_items() == false
	then
    ui:error("Failed to open sync file '"..path.."'. Wrong password?")
    return nil
  end
end

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


sync.update_box=function(self, box, path)
local changed=false
local tmp

if GlobalDebug == true then io.stderr:write("sync:update_box '".. tostring(box.name) .. " from '" .. tostring(path) .. "' with password: '" .. tostring(box.password) .. "'\n") end
tmp=self:load(path, box.password)
if tmp ~= nil
then 
  if strutil.strlen(box.password) == 0 then box.password=tmp.password end
  if strutil.strlen(box.passhint) == 0 then box.passhint=tmp.passhint end

  if hosts:check_version(tmp.machine_id, tmp.name, tmp.version)==true
  then 
    print("sync importing..." ..path)
    self:import(box, tmp)
    changed=true
  end

  tmp:destroy()

  return(changed)
end
end





sync.send_path=function(self, path, dir)
local dst_path, final_path, name


if strutil.strlen(dir) > 0
then
  
   name=filesys.filename(path)
   dst_path=dir .. sys.hostname() .. "-" .. name ..".tmp"

   if string.sub(dir, 1, 4) == "ssh:" then SSHRunCommand("mkdir -p", dir)
   else filesys.mkdirPath(dst_path)
   end
  
   filesys.copy(path, dst_path)
   final_path=dir.. sys.hostname() .. "-" .. name ..".sync"

   if string.sub(dir, 1, 4) == "ssh:" then SSHRunCommand("mv -f ", dst_path, final_path)
	 else filesys.rename(dst_path, final_path)
	 end
   
   print("send lockbox '" .. name .."' at '"..path.."' to '"..final_path.."'")
end

end



sync.send=function(self, box, dir)
self:send_path(box.path, dir)
end




-- for each EXISTING lockbox, try to find an import
-- file that can be used to update it
sync.update=function(self, box)
local path, files, i, tmp
local changed=false

path=config:get("sync_in") .. "*-".. box.name .. ".sync"
files=get_filelist(path)
if GlobalDebug == true then io.stderr:write("update lockbox: '" .. box.name .. "' from '" .. tostring(path) .."' ".. tostring(#files) .. " files found.\n") end

for i,path in ipairs(files)
do
tmp=LockboxFromFile(path)
if tmp ~= nil
then
if strutil.strlen(box.password) > 0 then tmp.password=box.password end
tmp:load(false)
if self:import(box, tmp) then changed=true end
end

end

if changed==true then box:save() 
else 
  if GlobalDebug == true then io.stderr:write("update lockbox: '" .. box.name .. "' lockbox unchanged. not saving.\n") end
end


return changed
end


sync.update_by_name=function(self, name)
local box

box=lockboxes:find(name)
self:update(box)

end


-- import a bunch of files, use the name of the imported file to
-- update or create a lockbox for it
sync.import_items=function(self, item_list)
local i, result, error, toks, str
local glob, item

if strutil.strlen(item_list) == 0 then item_list=config:get("sync_in") .. "/*.sync" end

files=get_filelist(item_list)
if GlobalDebug == true then io.stderr:write("sync from '" .. item_list .. "' " .. tostring(#files) .. " files found.") end

for i, item in ipairs(files)
do
  result,error=lockboxes:sync(item) 
  if result ~= true then ui:error(error) end
end

end


sync.export_items=function(self, cmd)
local list, dir

dir=cmd.dir
if strutil.strlen(dir)==0
then
    dir=cmd.box
    if strutil.strlen(dir)==0 then dir=config:get("sync_out") end

    list=lockboxes:paths()
    for i,item in pairs(list)
    do
	    self:send_path(item, dir)    
    end
else
	self:send_path(cmd.box, cmd.dir)    
end

end



return sync
end
