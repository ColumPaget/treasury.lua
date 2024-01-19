importer={}


importer.read_fieldlist=function(self, fieldlist)
local toks, tok, key, value, fieldno
local fields={}
local fields_type="pos"

fieldno=1
toks=strutil.TOKENIZER(fieldlist, ",")
tok=toks:next()
while tok ~= nil
do
  pos=string.find(tok, '=')
  if pos ~= nil
  then
	key=string.sub(tok, 1, pos-1)
	value=string.sub(tok, pos + 1)
	fields[value]=key
	fields[key]=value
	fields_type="map"
  else
	fields[fieldno]=tok
	fieldno = fieldno + 1
  end

tok=toks:next()
end

return fields,fields_type
end



importer.map_field=function(self, fields, fieldname, fieldno)

if strutil.strlen(fieldname) > 0 then return fields[fieldname] end

return fields[fieldno]
end



importer.examine_file=function(self, path)
local S, ftype
local str=""

S=stream.STREAM(path)
if S ~= nil
then
for i=1,4,1 do str=str..S:readch() end

if str=="PK\003\004" then ftype="zip" 
elseif str=="7z\xBC\xAF" then ftype="7zip" 
elseif str=="U2Fs" then ftype="ssl" 
end

S:close()
end

return ftype
end


importer.open_zip=function(self, path)
local str, Proc, PtyS, S, password, doc

password=ui:ask_password("password for encrypted zip file:")
str="unzip -p " .. path 
Proc=process.PROCESS(str, "ptystream")

PtyS=Proc:get_pty()
PtyS:timeout(100)
str=PtyS:readto(':')
if strutil.strlen(str) > 0 and string.find(str, "password:") ~= nil
then
PtyS:writeln(password)
PtyS:flush()
end

S=Proc:get_stream()
return S
end



importer.open_7zip=function(self, path)
local str, password, Proc, PtyS

password=ui:ask_password("password for encrypted 7zip file: ")

str="7za x " .. path .. " -so"
Proc=process.PROCESS(str, "ptystream")

PtyS=Proc:get_pty()
S=Proc:get_stream()
str=ReadToPassword(S)
process.usleep(10000)
PtyS:writeln(password .. "\n")
PtyS:flush()

return Proc:get_stream()
end



importer.open_ssldecrypt=function(self, path)
local Proc, password, S

password=ui:ask_password("password for ssl encrypted import file:")
Proc=openssl:open_decrypt(password, path) 

S=Proc:get_stream()
return S, Proc
end






importer.import_type=function(self, doc, import_type)

if strutil.strlen(import_type) > 0 then return(import_type) end

if string.sub(doc, 1, 8) == "\xEF\xBB\xBF<?xml" then return("xml") end
if string.sub(doc, 1, 5) == "<?xml" then return("xml") end
if string.sub(doc, 1, 1) == "{" then return("json") end

return("csv")
end


importer.import=function(self, box, path, fieldlist, import_type)
local ftype, S

self.items_imported=0

if strutil.strlen(fieldlist) > 0 then self.fields,self.fields_type=self:read_fieldlist(fieldlist) end
if box:load() ~= true then return false end

ftype=self:examine_file(path)
if ftype == "7zip" then S=self:open_7zip(path)  
elseif ftype == "zip" then S=self:open_zip(path) 
elseif ftype == "ssl" then S=self:open_ssldecrypt(path) 
else S=stream.STREAM(path, "r")
end

if S ~= nil 
then
  doc=S:readdoc()
  if strutil.strlen(doc) > 0 then doctype=self:import_type(doc, import_type)
  else ui:error("No data to import. Wrong password?")
  end
  S:close()
else
  ui:error("Failed to open import file. Wrong password?")
end


if doctype == "json" then self:import_json(box, doc)
elseif doctype=="xml" then self:import_xml(box, doc)
else self:import_csv(box, doc)
end

print("IMPORTED: " .. tostring(self.items_imported) .. " lines")
box:save(true)
end
