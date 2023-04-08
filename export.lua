
exporter={}


exporter.csv=function(self, items, Out)
local str

if Out==nil then Out=stream.STREAM("-", "w") end

Out:writeln("key,value,notes,updated\n")
for key, item in pairs(items)
do
str=item.name .. "," .. item.value .. "," .. item.notes ..  "," .. item.updated.."\n"
Out:writeln(str)
end

Out:flush()

end

exporter.xml_item=function(self, name, value)
return "<"..name..">"..value.."</"..name..">"
end

exporter.xml=function(self, items, Out)
local str, key, item

if Out==nil then Out=stream.STREAM("stdout:") end

for key, item in pairs(items)
do
str="<item>".. self:xml_item("name", item.name) .. self:xml_item("value", item.value) .. self:xml_item("notes", item.notes) ..  self:xml_item("updated", item.updated) .. "</item>".."\n"
Out:writeln(str)
end

Out:flush()
end


exporter.json_item=function(self, name, value)
return "\"" .. name .."\": \"" .. value .."\",\n"
end

exporter.json=function(self, item, Out)
local str, key, item

if Out==nil then Out=stream.STREAM("stdout:") end

for key, item in pairs(items)
do
str="{\n" .. self:json_item("name", item.name) .. self:json_item("value", item.value) .. self:json_item("notes", item.notes) ..  self:json_item("updated", item.updated) .. "}\n"
Out:writeln(str)
end

Out:flush()
end


exporter.openzip=function(self, export_path)
local str, password, Proc, PtyS

password=QueryPassword("password for exported zip file: ")

str="zip " .. export_path .. " -e -"
Proc=process.PROCESS(str, "ptystream")

PtyS=Proc:get_pty()
str=PtyS:readto(':')
PtyS:writeln(password .. "\n")
PtyS:flush()

str=PtyS:readto(':')
PtyS:writeln(password .. "\n")
PtyS:flush()

return Proc
end

exporter.open7zip=function(self, export_path)
local str, password, Proc, PtyS

password=QueryPassword("password for exported 7zip file: ")

str="7za a " .. export_path .. " -p -si"
print(str)
Proc=process.PROCESS(str, "ptystream")

PtyS=Proc:get_pty()
S=Proc:get_stream()
str=ReadToPassword(S)
process.usleep(10000)
PtyS:writeln(password .. "\n")
PtyS:flush()

str=ReadToPassword(S)
process.usleep(10000)
PtyS:writeln(password .. "\n")
PtyS:flush()

return Proc
end


exporter.open_sslencrypt=function(self, export_path)
local password, Proc

password=QueryPassword("password for exported openssl encrypted file: ")
Proc=openssl:open_encrypt(password, export_path)

return Proc
end



exporter.open_container=function(self, ftype, path)
local Proc

if ftype=="ssl" then 
Proc=self:open_sslencrypt(path)
elseif ftype=="7zip" then 
Proc=self:open7zip(path)
else
Proc=self:openzip(path)
end

return Proc
end




exporter.zipcsv=function(self, ftype, path, items)
local Proc, S

Proc=self:open_container(ftype, path)
S=Proc:get_stream()
self:csv(items, S)
S:commit()
process.sleep(1)
S:close()
Proc:wait_exit()

end

exporter.zipxml=function(self, ftype, path, items)
local Proc, S

Proc=self:open_container(ftype, path)
S=Proc:get_stream()
self:xml(items, S)
end


exporter.zipjson=function(self, ftype, path, items)
local Proc, S

Proc=self:open_container(ftype, path)
S=Proc:get_stream()
self:json(items, S)
end




exporter.sslcsv=function(self, ftype, path, items)
local Proc, S

Proc=self:open_container(ftype, path)
S=Proc:get_stream()
self:csv(items, S)
S:commit()
process.sleep(1)
S:close()
Proc:wait_exit()

end

exporter.sslxml=function(self, ftype, path, items)
local Proc, S

Proc=self:open_container(ftype, path)
S=Proc:get_stream()
self:xml(items, S)
end


exporter.ssljson=function(self, ftype, path, items)
local Proc, S

Proc=self:open_container(ftype, path)
S=Proc:get_stream()
self:json(items, S)
end



exporter.select_items=function(self, selectlist, items)
local toks, tok
local selected={}

toks=strutil.TOKENIZER(selectlist, ",")
tok=toks:next()
while tok ~= nil
do
	selected[tok]=items[tok]
	tok=toks:next()
end

return selected
end



exporter.export=function(self, cmd)
local box
local items

box=lockboxes:find(cmd.box)
if box==nil
then
ErrorMsg("ERROR: no such lockbox '"..cmd.box.."'")
return
end


box:load()

if strutil.strlen(cmd.items) > 0
then
  items=self:select_items(cmd.items, box.items)
  
else
  items=box.items
end


print("export: type="..cmd.import_type.." to "..cmd.path)
if cmd.import_type == "csv" then exporter:csv(items, cmd.path) 
elseif cmd.import_type == "xml" then exporter:xml(items, cmd.path) 
elseif cmd.import_type == "json" then exporter:json(items, cmd.path) 
elseif cmd.import_type == "zip.csv" then exporter:zipcsv("zip", cmd.path, items) 
elseif cmd.import_type == "zip.xml" then exporter:zipxml("zip", cmd.path, items) 
elseif cmd.import_type == "zip.json" then exporter:zipjson("zip", cmd.path, items) 
elseif cmd.import_type == "7zip.csv" then exporter:zipcsv("7zip", cmd.path, items) 
elseif cmd.import_type == "7zip.xml" then exporter:zipxml("7zip", cmd.path, items) 
elseif cmd.import_type == "7zip.json" then exporter:zipjson("7zip", cmd.path, items) 
elseif cmd.import_type == "ssl.csv" then exporter:sslcsv("ssl", cmd.path, items) 
elseif cmd.import_type == "ssl.xml" then exporter:sslxml("ssl", cmd.path, items) 
elseif cmd.import_type == "ssl.json" then exporter:ssljson("ssl", cmd.path, items) 
end

end


