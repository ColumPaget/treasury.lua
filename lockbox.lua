


function LockboxCreate(name, path, password, hint)
local lockbox, str

--initial lockbox setup
lockbox={}
lockbox.name=name
lockbox.password=password
lockbox.passhint=hint
lockbox.version=0
lockbox.suppress_errors=false
lockbox.items={}

if strutil.strlen(path) == 0 then lockbox.path=lockboxes:path(name)
else lockbox.path=path
end


-- from here on is member functions of 'lockbox'

lockbox.saveencrypted=function(self, data, Dest)
local str, Proc, S

Proc=openssl:open_encrypt(self.password)
if Proc ~= nil
then
S=Proc:get_stream()
--send data to openssl for encryption
S:writeln(data)
S:commit()
--process.sleep(5)

--read back the encrypted data
str=S:readdoc()
openssl:close_crypt(Proc)

--write encrypted data to our lockbox file
Dest:writeln(str)
end
end


lockbox.save_fmt_item=function(self, name, value)
return(name .. "=\"" .. strutil.quoteChars(value, "|\r\n\"")  .. "\" ")
end


lockbox.save=function(self, do_sync)
local str, S, key, item, name, value

if strutil.strlen(self.password) == 0 then self.password=ui:ask_password("Password for "..self.name..": ~>") end

filesys.mkdirPath(self.path)
S=stream.STREAM(self.path, "w")
if S ~= nil
then
	--save lockbox file header
	self.filefmt="kv"
	self.version=self.version + 1
	S:writeln("name:"..self.name.."\n")
	if strutil.strlen(self.passhint) > 0 then S:writeln("passhint:" .. self.passhint .. "\n") end
	if self.version ~= nil then S:writeln("version:"..tostring(self.version) .. "\n") end
	if self.filefmt ~= nil then S:writeln("filefmt:"..tostring(self.filefmt) .. "\n") end
	S:writeln("machine_id:" .. hosts.my_id() .. "\n")
	S:writeln("updated:"..time.format("%Y-%m-%dT%H:%M:%S").."\n\n")


	str=""
	for key,item in pairs(self.items)
	do
		str=str .. key .. " "
		for name,value in pairs(item)
		do
		if name ~= "name" then str=str..self:save_fmt_item(name, value) end
		end
		str=str ..  "\n"
	end

	self:saveencrypted(str, S)
	S:close()
	if dosync == true then sync:send(self) end
end

end




lockbox.add_item=function(self, item)
if strutil.strlen(item.updated) == 0 then item.updated=time.format("%Y/%m/%dT%H:%M:%S") end

self.items[item.name]=item
end



lockbox.add=function(self, name, value, notes, updated, item_type)
local item

name=strutil.quoteChars(name, "|")

item={}
if item.type ~= nil then item.type=item_type
else item.type=""
end

item.type=item_type 
item.name=name
item.value=value
item.notes=notes
item.updated=updated

self:add_item(item)
end




lockbox.parse_kv=function(self, data, item)
local toks, key, str

toks=strutil.TOKENIZER(data, "=", "Q")
key=toks:next()
if strutil.strlen(key) > 0 then item[key]=strutil.unQuote(toks:next()) end
end


lockbox.add_kv_item=function(self, data)
local toks, tok 
local item={}

--these will get overwritten if they exist in data
item.type=""
item.updated=time.format("%Y/%m/%dT%H:%M:%S") 

-- go through data parsing name/value pairs
toks=strutil.TOKENIZER(data, "\\S", "Q")
item.name=toks:next()
tok=toks:next()
while tok ~= nil
do
self:parse_kv(tok, item)
tok=toks:next()
end

self.items[item.name]=item
end



lockbox.parse_item=function(self, data)
local toks, tok

lockbox:add_kv_item(data)

end



lockbox.parse_items=function(self, data)
local lines, line

lines=strutil.TOKENIZER(data, "\n")
line=lines:next()
while line ~= nil
do
self:parse_item(line)
line=lines:next()
end

end




lockbox.remove=function(self, key)
self.items[key]=nil
end




lockbox.readencrypted=function(self, encrypt)
local S, PtyS, Proc
local str=""

Proc=openssl:open_decrypt(self.password, nil, self.suppress_errors)
if Proc ~= nil
then

S=Proc:get_stream()
S:writeln(encrypt .. "\n")  --some versions of openssl expect base64 encoded data to end with a newline
S:commit()
S:timeout(500)

str=S:readdoc()

if openssl:close_crypt(Proc) ~= true
then 
if config:get("syslog") == "y" then syslog.alert("treasury.lua: incorrect password for lockbox '%s'", self.name) end
return nil 
end

end

return str
end



lockbox.read_info=function(self, S)
local str, toks, tok

self.version=0
self.machine_id=""

str=S:readln()
while str ~= nil
do
	str=strutil.trim(str)

	if strutil.strlen(str) == 0 then break end

	toks=strutil.TOKENIZER(str, ":")
	tok=toks:next()
	if tok=="name" then self.name=toks:remaining()
	elseif tok=="machine_id" then self.machine_id=toks:remaining() 
	elseif tok=="updated" then self.updated=toks:remaining() 
	elseif tok=="version" then self.version=tonumber(toks:remaining())
	elseif tok=="passhint" then self.passhint=toks:remaining() 
	elseif tok=="filefmt" then self.filefmt=toks:remaining() 
	end

	str=S:readln()
end


end


lockbox.examine=function(self)
local S

S=stream.STREAM(self.path, "r")
if S ~= nil
then
	self:read_info(S)
	S:close()
	return true
end

return false
end



lockbox.read=function(self)
local S
local str=""
local queried_password=false

S=stream.STREAM(self.path, "r")
if S ~= nil
then
self:read_info(S)
if strutil.strlen(self.password) == 0 and config:get("keyring") == "y" then self.password=keyring:get(self.name) end
if strutil.strlen(self.password) == 0 
then
	self.password=ui:ask_password("Password for "..self.name..": ~>", self.passhint) 
	queried_password=true
end

str=self:readencrypted(S:readdoc())

if queried_password == true and strutil.strlen(str) > 0 and config:get("keyring") ~= "n" then keyring:set(self.name, self.password) end
S:close()
end

return str
end



-- load without importing synced items
lockbox.load_items=function(self)
local str

str=self:read()
if str==nil then return false end
self:parse_items(str)
return true
end


lockbox.load=function(self)
local result

result=self:load_items()
sync:update(self)
return result 
end


lockbox.get=function(self, name)
local key, item

for key,item in pairs(self.items)
do
if key==name then return item end
end

return nil
end


lockbox.destroy=function(self)
ScrubFile(self.path)
filesys.unlink(self.path)
end


return lockbox
end


