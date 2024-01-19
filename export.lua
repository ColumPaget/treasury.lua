
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

exporter.json=function(self, items, Out)
local str, key, item

if Out==nil then Out=stream.STREAM("stdout:") end

Out:writeln("{\n")
for key, item in pairs(items)
do
str="{\n" .. self:json_item("name", item.name) .. self:json_item("value", item.value) .. self:json_item("notes", item.notes) ..  self:json_item("updated", item.updated) .. "},\n"
Out:writeln(str)
end
Out:writeln("}\n")

Out:flush()
end


exporter.openzip=function(self, export_path)
local str, password, Proc, PtyS

password=ui:ask_password("password for exported zip file: ")

str="zip " .. export_path .. " -e -"
Proc=process.PROCESS(str, "rw ptystream ptystderr")

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

password=ui:ask_password("password for exported 7zip file: ")

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

password=ui:ask_password("password for exported openssl encrypted file: ")
Proc=openssl:open_encrypt(password, export_path)

return Proc
end



exporter.open_container=function(self, ftype, path)
local Proc

if ftype=="ssl" then 
Proc=self:open_sslencrypt(path)
elseif ftype=="7zip" then 
Proc=self:open7zip(path)
elseif ftype=="zip" then 
Proc=self:openzip(path)
end

return Proc
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


exporter.export_filetype=function(self, export_type, package_type, items, path)
local Proc, S

if strutil.strlen(package_type) > 0 
then
Proc=self:open_container(package_type, path)
S=Proc:get_stream()
else
S=stream.STREAM(path, "w")
end

if export_type == "csv" then self:csv(items, S)
elseif export_type == "xml" then self:xml(items, S)
elseif export_type == "json" then self:json(items, S)
end

S:commit()
process.sleep(1)
S:close()
--if Proc ~= nil then Proc:wait_exit() end
end




exporter.export=function(self, cmd)
local box
local items

box=lockboxes:find(cmd.box)
if box==nil
then
ui:error("ERROR: no such lockbox '"..cmd.box.."'")
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
if cmd.import_type == "csv" then exporter:export_filetype("csv", "", items, cmd.path) 
elseif cmd.import_type == "xml" then exporter:export_filetype("xml", "", items, cmd.path) 
elseif cmd.import_type == "json" then exporter:export_filetype("json", "", items, cmd.path) 
elseif cmd.import_type == "zip.csv" then exporter:export_filetype("csv", "zip", items, cmd.path) 
elseif cmd.import_type == "zip.xml" then exporter:export_filetype("xml", "zip", items, cmd.path) 
elseif cmd.import_type == "zip.json" then exporter:export_filetype("json", "zip", items, cmd.path) 
elseif cmd.import_type == "7zip.csv" then exporter:export_filetype("csv", "7zip", items, cmd.path) 
elseif cmd.import_type == "7zip.xml" then exporter:export_filetype("xml", "7zip", items, cmd.path) 
elseif cmd.import_type == "7zip.json" then exporter:export_filetype("json", "7zip", items, cmd.path) 
elseif cmd.import_type == "ssl.csv" then exporter:export_filetype("csv", "ssl", items, cmd.path) 
elseif cmd.import_type == "ssl.xml" then exporter:export_filetype("xml", "ssl", items, cmd.path) 
elseif cmd.import_type == "ssl.json" then exporter:export_filetype("json", "ssl", items, cmd.path) 
end

end


