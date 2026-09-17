function SyncInit()
local sync={}

sync.import_hashes={}
sync.hashes_loaded=false
sync.hashes_changed=false


-- load a list of hashes of files we imported so we don't try to import the same file again
sync.load_hashes=function(self)
local str, toks, key, item
local S

if self.hashes_loaded == false
then
S=stream.STREAM(config:get("sync_in") ..  "/imported.hashes", "r")
if S ~= nil
then
  str=S:readln()
  while str ~= nil
  do
  str=strutil.trim(str)
  toks=strutil.TOKENIZER(str, " ", "q")
  key=toks:next()
  item={}
  item.when=toks:next()
  item.hash=toks:remaining()
  self.import_hashes[key]=item
  str=S:readln()
  end

  S:close()

  self.hashes_loaded=true
end
end

return(import_hashes)
end



-- save a list of hashes of files we imported so we don't try to import the same file again
sync.save_hashes=function(self)
local S
local key, item 

if self.hashes_changed == true
then

   S=stream.STREAM(config:get("sync_in") ..  "/imported.hashes", "w")
   if S ~= nil
   then
     for key, item in pairs(self.import_hashes)
     do
       S:writeln(key .. " " .. item.when .. " " .. item.hash .. "\n")
     end
   S:close()
   end
   
end
end



sync.add_hash=function(self, name, hash, lockbox)
local item={}

item.when=time.format("%Y-%m-%dT%H:%M:%S")
item.hash=hash
self.import_hashes[name]=item
self.hashes_changed=true

end


sync.del_hash=function(self, path)

fname=filesys.basename(path)
self.import_hashes[fname]=nil

end


sync.check_hash=function(self, path)
local fname, fhash, item

fname=filesys.basename(path)
fhash=hash.hashfile(path, "sha1", "p64")


item=self.import_hashes[fname] 
if item ~= nil and item.hash == fhash then return true end

self:add_hash(fname, fhash)

return false
end

sync.display_last_syncs=function(self)
local when, diff, str
local lines=0

sync:load_hashes()

for key, item in pairs(self.import_hashes)
do
when=time.tosecs("%Y-%m-%dT%H:%M:%S", item.when)

str=""
diff=(time.secs() - when)

if diff > (3600 * 24 * 30) then str=str.."~er"
elseif diff > (3600 * 24 * 7) then str=str.."~ey"
elseif diff < (3600 * 24) then str=str.."~e"
end

str=str..item.when.."~0 "
str=str..item.hash.."  "
str=str..key.." "
str=str.."\n"

lines=lines+1
Term:puts(str)
end

if lines == 0 then print("No sync file imports have been recorded.") end

end



sync.examine_import_file=function(self, path, password)
local info

-- this will only happen once, because it internally checks a flag
-- to see if already loaded
self:load_hashes()
info=LockboxFromFile(path, password)

if info ~= nil then info.already_loaded=self:check_hash(path)
else ui:error("cant open sync file: "..tostring(path)) 
end

return info
end






sync.import_item=function(self, existing, new) 
local exist_time, new_time
local changed=false

exist_time=time.tosecs("%Y/%m/%dT%H:%M:%S", existing.updated)
new_time=time.tosecs("%Y/%m/%dT%H:%M:%S", new.updated)

if new_time > exist_time
then
existing.updated=new.updated
existing.value=new.value
changed=true
end

return changed
end




sync.import=function(self, box, other)
local key, item
local changed=false

for key,item in pairs(other.items)
do
  existing=box.items[key]
  if existing ~= nil then changed=self:import_item(existing, item) 
  else
     box.items[key]=item
           changed=true
  end
end

return changed
end









-- import items to an EXISTING lockbox
sync.update_box=function(self, box, path)
local changed=false
local tmp

if GlobalDebug == true then io.stderr:write("sync:update_box '".. tostring(box.name) .. " from '" .. tostring(path) .. "' with password: '" .. tostring(box.password) .. "'\n") end

tmp=self:examine_import_file(path)
if tmp ~= nil
then 
    --if box already has a password, then use it
    tmp.password=box.password

  if tmp.already_loaded == true then print("ignoring previously imported file '"..path.."'")
  elseif tmp:load(false) == false then ui:error("Failed to decrypt import file. Wrong password?")
  elseif hosts:check_version(tmp.machine_id, tmp.name, tmp.version) == false then print("import file has older version than lockbox '" .. box.name .. "'  ".. tostring(tmp.version) .." < "..tostring(box.version))
  else
      print("sync importing..." ..path)
      if strutil.strlen(box.password) == 0 then box.password=tmp.password end
      if strutil.strlen(box.passhint) == 0 then box.passhint=tmp.passhint end
  
      self:import(box, tmp)
      changed=true
  end
  tmp:destroy()
end

return(changed)
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
changed=self:update_box(box, path)
end


if changed == true then box:save() 
else 
  if GlobalDebug == true then io.stderr:write("update lockbox: '" .. box.name .. "' lockbox unchanged. not saving.\n") end
end


return changed
end


-- for an EXISTING lockbox, with supplied name, do update
sync.update_by_name=function(self, name)
local box

box=lockboxes:find(name)
self:update(box)

end




sync.import_open_or_create=function(self, name, password, passhint)
local box

   box=lockboxes:find(name)
   if box == nil 
   then 
     box=LockboxCreate(name, nil, password, passhint)
     if box == nil then return nil,"unable to create lockbox" end
   else
     if box:load(false) == false
     then
      ui:error("incorrect password for destination lockbox")
      box.password=ui:ask_password("Enter password for destination lockbox '"..box.name.."': ", box.passhint)
      if box:load(false) == false then return nil, "incorrect password for destination lockbox, abandoning sync." end
     end 
   end

return box
end



-- import a single file, use name of the imported file to
-- update or create a lockbox for it, so here the destination box might not exist
sync.import_file=function(self, path)
local tmp, box

-- we must open tmp file in order to get a 'trust worthy' name for it
tmp=self:examine_import_file(path)
if tmp == nil then return end

-- always display this so the user knows what is happening and which lockbox is being dealt with
print("sync from file '" .. tostring(path) .. "' to lockbox '" .. tmp.name .. "'") 
 
if tmp.already_loaded == true then print("ignoring previously imported file '"..path.."'")
elseif tmp:load(false) == false then ui:error("Failed to decrypt import file. Wrong password?")
else
  
   
   box,error=self:import_open_or_create(tmp.name, tmp.password, tmp.passhint)
   
   if box == nil 
   then 
   self:del_hash(path)
   ui:error(error)
   return false
   end
   
--[[
   if strutil.strlen(box.password) > 0 then tmp.password=box.password end
   if strutil.strlen(box.passhint) > 0 then tmp.password=box.passhint end
]]--
   
   if self:import(box, tmp) == true then box:save() 


end
end


tmp:destroy()

return true

end


-- import a bunch of files, use the name of the imported file to
-- update or create a lockbox for it, so here the destination box might not exist
sync.import_files=function(self, item_list)
local i, result, error, toks, fname, fhash
local glob, path

self:load_hashes()

if strutil.strlen(item_list) == 0 then item_list=config:get("sync_in") .. "/*.sync" end

files=get_filelist(item_list)
if GlobalDebug == true then io.stderr:write("sync from '" .. item_list .. "' " .. tostring(#files) .. " files found.") end

print(tostring(#files) .. " sync files for import")

for i, path in ipairs(files)
do
  self:import_file(path) 
end


self:save_hashes(import_hashes)

end





-- Functions below this point relate to exporting or 'sending' files

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




