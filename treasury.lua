require("dataparser")
require("terminal")
require("filesys")
require("entropy")
require("stream")
require("process")
require("strutil")
require("syslog")
require("time")
require("hash")
require("sys")
function ConfigInit()
local config={}

config.items={}


config.path=function()
return process.getenv("HOME").."/.config/treasury/treasury.conf"
end


config.set=function(self, name, value)
self.items[name]=value
end


config.set_bool=function(self, name, value)

if value=="true" or value=="Y" or value=="y" or value=="yes" then self:set(name, "y")
elseif value=="false" or value=="N" or value=="n" or value=="no" then self:set(name, "n")
else
	ui:error("Invalid value '"..value.."' for boolean setting '"..name.."'. Valid values: 'true','false','Y','N','y','n'")
	return false
end

return true

end


config.set_choice=function(self, name, value, choices)
local choice, replace
local str=""

for i,choice in pairs(choices)
do
	str=str..choice..","
	if choice == value
	then
		self:set(name, value)
		return true
	end
end

ui:error("Invalid value '" .. value .. " for setting '" .. name .. "'. Valid values:  " .. str)

return false
end


config.get=function(self, name)
local str
str=self.items[name]
if str==nil then str="" end
return str
end


config.load=function(self)
local S, str, toks, tok

S=stream.STREAM(self:path(), "r")
if S ~= nil
then
str=S:readln()
while str ~= nil
do
	str=strutil.trim(str)
	toks=strutil.TOKENIZER(str, "=", "Q")
	self.items[toks:next()]=toks:remaining()
	str=S:readln()
end
S:close()
end

end



config.save=function(self)
local S, key, value, tmppath

tmppath=self:path()..".new"
filesys.mkdirPath(tmppath, 0700)
S=stream.STREAM(tmppath, "w")
if S ~= nil
then
	for key,value in pairs(self.items)
	do
		S:writeln("'"..key.."'="..value.."\n")
	end
	S:close()
	filesys.rename(tmppath, self:path())
end

end


config.output=function(self)
local key, value

for key,value in pairs(self.items)
do
		print("'"..key.."'="..tostring(value))
end
end


config.change=function(self, name, value)

if self.items[name] == nil 
then
	ui:error("no such config setting: '"..name.."'")
	return false
elseif name=="mlock" or name=="scrub_files" or name=="syslog" or name=="keyring"
then
	if config:set_bool(name, value) == false then return false end
elseif name=="pass_hide"
then 
	if config:set_choice(name, value, {"show", "hide", "stars", "stars+1"} ) == false then return false end
	config:set(name, value)
end

config:save()
end


config:set("clip_cmd", "xsel -i -p -b,xclip -selection clipboard,pbcopy")
config:set("iview_cmd", "convert,imlib2_view,fim,feh,display,xv,phototonic,qimageviewer,pix,sxiv,qimgv,qview,nomacs,geeqie,ristretto,mirage,fotowall,links -g,convert")
config:set("edit_cmd", "vim,vi,pico,nano")
config:set("digest", "sha256")
config:set("algo", "aes-256-cbc")
config:set("pass_hide", "stars+1")
config:set("syslog", "y")
config:set("mlock", "n")
config:set("scrub_files", "n")
config:set("resist_strace", "n")
config:set("keyring", "n")
config:set("keyring_timeout", "3600")

config:load()

if config:get("pass_hide")=="hide" then config:set("pass_hide", "hidetext") end

return config

end

function FindExecutable(cmd)
local toks, tok, prog, path

toks=strutil.TOKENIZER(cmd, "\\S")
tok=toks:next()
path=filesys.find(tok, process.getenv("PATH"))
if strutil.strlen(path) > 0 then return(path .. " " ..toks:remaining()) end

return nil
end


function FindCmd(candidates)
local toks, tok, cmd

toks=strutil.TOKENIZER(candidates, ",")
tok=toks:next()
while tok ~= nil
do
cmd=FindExecutable(tok)
if strutil.strlen(cmd) > 0 then return(cmd) end
tok=toks:next()
end

return nil
end



function DeduceFileTypeFromPath(path)
local str

str=filesys.extn(path)
if strutil.strlen(str) ==0 then return("ssl.csv") end

if str==".csv" then return("csv") end
if str==".xml" then return("xml") end
if str==".json" then return("json") end
if str==".zcsv" then return("zip.csv") end
if str==".zxml" then return("zip.xml") end
if str==".zjson" then return("zip.json") end
if str==".zipcsv" then return("zip.csv") end
if str==".zipxml" then return("zip.xml") end
if str==".zipjson" then return("zip.json") end
if str==".7zcsv" then return("7zip.csv") end
if str==".7zxml" then return("7zip.xml") end
if str==".7zjson" then return("7zip.json") end
if str==".7zipcsv" then return("7zip.csv") end
if str==".7zipxml" then return("7zip.xml") end
if str==".7zipjson" then return("7zip.json") end
if str==".scsv" then return("ssl.csv") end
if str==".sxml" then return("ssl.xml") end
if str==".sjson" then return("ssl.json") end
if str==".sslcsv" then return("ssl.csv") end
if str==".sslxml" then return("ssl.xml") end
if str==".ssljson" then return("ssl.json") end

return(string.sub(extn, 2))
end


function ScrubFile(path)
local S, str, len


if config:get("scrub_files") == "y"
then
len=filesys.size(path)
S=stream.STREAM(path, "w")

if S ~= nil
then
	for i=1,len,1
	do
	  val=math.floor(math.random() * 255)
	  S:write(string.char(val), 1)
	end
	S:close()
else
	ui:error("failed to scrub/overwrite: ".. path)
end

end

filesys.unlink(path)
if filesys.exists(path) == true then ui:error("failed to delete: ".. path) end
end

function ReadToPassword(S)
local str

str=S:readto(":")
while str ~= nil
do
if string.find(str, "password") ~= nil then return str end
str=S:readto(":")
end

return nil
end

function EditorLaunch()
local path, S, str, cmd

	cmd=FindCmd(config:get("edit_cmd"))
	if cmd==nil then return nil end

	path=process.getenv("HOME") .. "/.treasury/" .. tostring(process.pid()) .. ".data"
	os.execute(cmd.." "..path)

	str=""
	S=stream.STREAM(path, "r")
	if S ~= nil
	then
	str=S:readdoc()
	S:close()
	ScrubFile(path)
	end

	return(str)
end


function QRCodeCreate(value, path, args)
local cmd, S, str

cmd=FindCmd("qrencode")
if cmd ~= nil
then
	str="cmd:" .. cmd 
	if strutil.strlen(path) > 0 then str=str .. " -o " .. path end
	if strutil.strlen(args) > 0 then str=str .. " " ..args end

  S=stream.STREAM(str)
  if S ~= nil
  then
  	S:writeln(value)
  	S:commit()
  	str=S:readdoc()
		print(str)
  	S:close()
  end
end

end



function DisplayQRCode(value, output_path)
local S, str, path, cmd, viewer

if strutil.strlen(output_path) > 0 then path=output_path
else path="/tmp/.treasury_qrcode.png"
end

viewer=FindCmd(config:get("iview_cmd"))

if strutil.strlen(viewer) == 0 then QRCodeCreate(value, "-", " -t ANSI256")
else QRCodeCreate(value, path)
end

-- if output_path is set, then we just write the png file to that path,
-- we don't display it, and we don't scrub/delete the file
if strutil.strlen(output_path) ==0 and strutil.strlen(viewer) > 0
then
  str=viewer .. " " .. path
  if viewer=="convert" then str=str.." sixel:-" end 

 	if viewer ~= nil then os.execute(str) end
 	ScrubFile(path)
end

end



function FindClipboardCmd()
local toks, tok, cmd

str=FindCmd(config:get("clip_cmd"))
if strutil.strlen(str)==0 then return "xterm" end
return str
end


function RunClipboardCmd(cmd, text)
local proc, S

  proc=process.PROCESS(cmd)
  if proc ~= nil
  then
	S=proc:get_stream()
	if S ~= nil
	then
		S:writeln(text)
		proc:wait_exit();
	end
  end
end


function ToClipboard(text, use_osc52)
local cmd

cmd=FindClipboardCmd()

if use_osc52 == true
then
	Term:xterm_set_clipboard(text)
elseif strutil.strlen(cmd) > 0
then
   if cmd == "xterm" then Term:xterm_set_clipboard(text)
   else RunClipboardCmd(cmd, text)
   end
end

end
keyring={}

keyring.set_timeout=function(self, key_id, timeout)
local S
local str

if strutil.strlen(key_id) > 0 and tonumber(timeout) > 0
then
  str="cmd:keyctl timeout " .. key_id .. " " .. tostring(timeout)
  S=stream.STREAM(str, "")
  if S ~= nil
  then
    str=S:readln()
    S:close()
  end
end

end


keyring.get_by_id=function(self, id)
local str, S

if strutil.strlen(id) > 0
then
  S=stream.STREAM("cmd:keyctl pipe "..id,"rw stderr2null")
  if S ~= nil
  then
     str=strutil.trim(S:readln())
     S:close()
  end
end

return(str)
end


keyring.get=function(self, lockbox_name)
local S, id

S=stream.STREAM("cmd:keyctl search @s user 'treasury.lua:"..lockbox_name.."'","rw stderr2null")
if S ~= nil
then
id=strutil.trim(S:readln())
if id ~= nil then self:set_timeout(id, config:get("keyring_timeout")) end
S:close()
end

return(self:get_by_id(id))
end


keyring.add_key=function(self, lockbox_name, password, keyring)
local S
local id, str


str="cmd:keyctl padd user 'treasury.lua:"..lockbox_name.."' "..keyring
S=stream.STREAM(str,  "")
if S ~= nil
then
S:writeln(password.."\r\n")
S:commit()
id=strutil.trim(S:readln())
S:close()
end
return(id)
end


keyring.set_in_keyring=function(self, lockbox_name, password, keyring)
local id, str

id=self:add_key(lockbox_name, password, keyring)
if strutil.strlen(id) > 0
then
str=self:get_by_id(id)
if str==password then return(id) end
end

return(nil)
end


keyring.set=function(self, lockbox_name, password)
local id

id=self:set_in_keyring(lockbox_name, password, "@s")
-- fall back to user keyring if no session keyring
if id==nil then id=self:set_in_keyring(lockbox_name, password, "@u") end
if id ~= nil then self:set_timeout(id, config:get("keyring_timeout")) end

end




function SyncInit()
local sync={}


sync.load=function(self, path, password)
local tmp

tmp=LockboxCreate("", path, password)
if tmp==nil then return nil end
if tmp:examine() == false then return nil end
if strutil.strlen(tmp.name) == 0 then return nil end

--if tmp.password == nil then
tmp.password=ui:ask_password("Enter Password for sync file '"..filesys.basename(path).."': ", tmp.passhint)
--end

tmp.suppress_errors=true
if tmp:load_items() == false
then 
ui:error("Failed to open sync file '"..path.."'. Wrong password?")
return nil
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
--[[
This module relates to storing a version number for each lockbox on each host.
using this we can detect if a lockbox should be imported or not
]]--

function HostsInit()
local hosts={}

hosts.items={}

hosts.path=function()
return process.getenv("HOME").."/.treasury/hosts.dat"
end

-- generate a unique id for our host
hosts.my_id=function(self)
local S, str
local long_id=""

str=stream.get("/etc/machine-id")
if str ~= nil then long_id=long_id..str.."-" end
str=stream.get("/sys/class/dmi/id/board_asset_tag")
if str ~= nil then long_id=long_id..str.."-" end

if strutil.strlen(long_id)==0
then
-- this is the MAC address of eth0, only use it if we've found nothing better
str=stream.get("/sys/class/net/eth0/address")
if str ~= nil then long_id=long_id..str.."-" end
end

if strutil.strlen(long_id)==0
then
-- this is the MAC address of wlan0, only use it if we've found nothing better
str=stream.get("/sys/class/net/wlan0/address")
if str ~= nil then long_id=long_id..str.."-" end
end

str=sys.hostname() .. "-".. hash.hashstr(long_id, "md5", "p64")

return str
end



--load our list of stored version nummbers for host lockboxes
hosts.load=function(self)
local S, str, toks, tok

S=stream.STREAM(self:path(), "r")
if S ~= nil
then
 str=S:readln()
 while str ~= nil
 do
  str=strutil.trim(str)
  toks=strutil.TOKENIZER(str, " ")
  self.items[toks:next()]=tonumber(toks:remaining())
  str=S:readln()
 end
 S:close()
end
end


hosts.save=function(self)
local S, id, version

S=stream.STREAM(self:path(), "w")
if S ~= nil
then
  for id,version in pairs(self.items)
  do
	S:writeln(id.." "..tostring(version).."\n")
  end
 S:close()
end
end


hosts.update=function(self, hostid, version)
self.items[hostid]=version
end



hosts.check_version=function(self, hostid, version)

-- no previous version for this hostid, we must need to import
if self.items[hostid] == nil then return true end
if self.items[hostid] < tonumber(version) then return true end
return false
end

return hosts
end
openssl={}


openssl.open_encrypt=function(self, password, output_path)
local str, Proc, PtyS

str="openssl enc -a -md " .. config:get("digest") .." -"..config:get("algo") .. " -pbkdf2"
-- .. " -iter 1000"
if strutil.strlen(output_path) > 0 then str=str .. " -out " .. output_path end

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


openssl.open_decrypt=function(self, password, input_path, noerror)
local str, Proc, PtyS, args

str="openssl enc -d -a -md " .. config:get("digest") .." -"..config:get("algo") .. " -pbkdf2"
if strutil.strlen(input_path) > 0 then str=str .. " -in " .. input_path end

args="ptystream"
if noerror==true then args=args.." errnull" end
Proc=process.PROCESS(str, args)

PtyS=Proc:get_pty()

PtyS:readto(':')
PtyS:writeln(password .. "\n")
PtyS:flush()


return Proc
end


function openssl.close_crypt(self, Proc)
local S, str, pid, result

S=Proc:get_stream();
pid=S:getvalue("PeerPID")
S:close()

result=process.waitStatus(pid)
if result=="exit:0" then return true end
return false
end
function UI_Init()
local ui={}


ui.title_bar=function(self, text)
Term:move(0,0)
Term:puts(text.."~>~0")
end



ui.error=function(self, msg)
local str

if msg==nil then msg="" end

if Mode=="menu"
then
	Term:move(0, Term:height() -1)
	str=Term:puts("~R~w"..msg.."~>")
	Term:puts("~0")
else
	str=terminal.format("~r~eERROR: "..msg.."~0\n")
	io.stderr:write(str)
end

return str
end


ui.error_no_lockbox=function(self, box)
self:error("no such lockbox '"..box.."' for user '"..process.user().."'")
end


ui.query_bar=function(self, prompt)
local str

if Mode=="menu"
then
Term:move(0, Term:height() -1)
str=Term:prompt("~B~w"..prompt.."~>")
Term:puts("~0")
else
str=Term:prompt(prompt.."~>")
Term:puts("~0\n")
end

return str
end


ui.ask_lockbox_details=function(self, prompt)
local pass, hint

if prompt == nil then prompt="Password for new lockbox:" end
pass=Term:prompt(prompt, config:get("pass_hide"))
Term:puts("\n")

if strutil.strlen(pass) > 0 then hint=ui:query_bar("Password hint (leave blank for none):" ) end

return pass, hint
end



ui.ask_password=function(self, prompt, hint)
local str

if Mode=="menu"
then
Term:move(0, Term:height() -2)
if strutil.strlen(hint) > 0 then Term:puts("Password hint: "..hint.."\n") end
str=Term:prompt("~B~w"..prompt.."~>", config:get("pass_hide"))
Term:puts("~0")
else
if strutil.strlen(hint) > 0 then Term:puts("Password hint: "..hint.."\n") end
str=Term:prompt(prompt.."~>", config:get("pass_hide"))
Term:puts("~0\n")
end

return str
end



ui.new_item=function(self, box)
local key, value

key=ui:query_bar("Enter name/key for new item: ")
value=ui:query_bar("Enter value for new item: ")

box:add(key, value)
box:save()
end



ui.new_item_editor=function(self, box)
local key, value

key=ui:query_bar("Enter name/key for new item: ")
value=EditorLaunch()

box:add(key, value)
box:save()
end


return(ui)
end



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

if queried_password == true and strutil.strlen(str) > 0 and config:get("keyring") == "y" then keyring:set(self.name, self.password) end
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


-- this module deals with the 'list of lockboxes' object


function InitLockboxes()
lockboxes={}

lockboxes.path=function(self, name)
if string.sub(name, 1, 1)=='/' then return(name) end
return process.getenv("HOME") .. "/.treasury/" .. name ..".lb"
end



lockboxes.add=function(self, path)
local item, name


name=filesys.basename(path)
pos=string.find(name, '%.')
if pos > 1 then name=string.sub(name, 1, pos-1) end

item=LockboxCreate(name, path)
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

if string.sub(name, 1, 1) == '/' 
then 
if filesys.exists(name) then return(self:add(name)) end
return(nil)
end

for key,item in ipairs(self.items)
do
if item.name==name then return(item) end
end

--if we get here we didn't find it, try syncing
print("'"..name.."' does not exist... checking for sync files")
item=LockboxCreate(name)
if sync:update(item) == true then return(item) end
return(nil)

end


lockboxes.deposit=function(self, boxname, key, value, notes)
local box

box=self:find(boxname)
if box == nil then box=self:new(boxname) end

if box:load() == true
then
box:add(key, value, notes)
box:save(true)
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


importer.csv_map_fields=function(self, field_map, fields)
local toks, tok, count, field
local fieldlist={}

count=0
toks=strutil.TOKENIZER(fields, ",")
tok=toks:next()
while tok ~= nil
do
	field=field_map[tok] 
	if field == nil then field="notes" end
	count=count + 1
  fieldlist[count]=field

tok=toks:next()
end

return fieldlist
end



importer.import_csv_line=function(self, box, line, fields)
local toks, tok, field
local key=""
local value=""
local notes=""
local count=1

toks=strutil.TOKENIZER(line, ",", "Q")

tok=toks:next()
while tok ~= nil
do
  field=self:map_field(fields, "", count)
  count=count+1

  if field == "key" then key=tok
  elseif field == "value" then value=tok
  else notes=notes.." "..tok
  end

tok=toks:next()
end

if strutil.strlen(key) > 0 
then
 box:add(key, value, notes) 
 self.items_imported=self.items_imported + 1
 return(true)
end

return(false)
end



importer.import_csv=function(self, box, doc)
local lines, line

lines=strutil.TOKENIZER(doc, "\n", "Q")

if self.fields_type=="map" then fields=self:csv_map_fields(self.fields, lines:next())
else fields=self.fields
end


--if no fieldlist supplied then assume first line of file is a fieldlist
if fields==nil then fields=self:read_fieldlist(lines:next()) end


line=lines:next()
while line ~= nil
do
	self:import_csv_line(box, line, fields) 
	line=lines:next()
end


end


importer.import_json_item=function(self, box, item)
local keyname, valuename, notesname, updatedname, key, value, notes, updated

if self.fields ~= nil
then
keyname=self.fields["key"]
valuename=self.fields["value"]
notesname=self.fields["notes"]
updatedname=self.fields["updated"]

else
keyname="name"
valuename="value"
notesname="notes"
updatedname="updated"
end


key=item:value(keyname)
value=item:value(valuename)
notes=item:value(notesname)
updated=item:value(updatedname)


if strutil.strlen(key) > 0
then
box:add(key, value, notes, updated)
self.items_imported=self.items_imported + 1
end

end


importer.import_json_list=function(self, box, items)
local item

item=items:next()
while item ~= nil
do
	self:import_json_iterate(box, item)
	item=items:next()
end

end


importer.import_json_iterate=function(self, box, item)

if item == nil then return end

if item:type() == "array"
then 
  items=parent:subitems()
  self:import_json_list(box, items)
else self:import_json_item(box, item)
end

end


importer.import_json=function(self, box, doc)
local P, items, item

items=dataparser.PARSER("json", doc)
if items ~= nil then self:import_json_list(box, items) end

end


require("xml")

importer.import_xml_item=function(self, box, XML)
local tok
local item={}

tok=XML:next()
while tok ~= nil
do
if tok.type=="name" then item.name=XML:next().data
elseif tok.type=="value" then item.value=XML:next().data
elseif tok.type=="notes" then item.notes=XML:next().data
elseif tok.type=="type" then item.type=XML:next().data
elseif tok.type=="updated" then item.updated=XML:next().data
elseif tok.type=="/item" then break 
end

tok=XML:next()
end

box:add_item(item) 
self.items_imported=self.items_imported + 1

end



importer.import_xml=function(self, box, doc)
local XML, tok

XML=xml.XML(doc)
tok=XML:next()
while tok ~= nil
do
if tok.type=="item" then self:import_xml_item(box, XML) end
tok=XML:next()
end

end

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


function CommandLineParse(args)
local cmd={}

cmd.to_clipboard=false
cmd.osc52_clip=false
cmd.qr_code=false
cmd.csv=false
cmd.json=false
cmd.value=""
cmd.notes=""
cmd.fieldlist=""
cmd.items=""
cmd.generate=0

for i,value in ipairs(args)
do
	-- FIRST ARGUMENT IS THE COMMAND, CommandLineParse ONLY PARSES OPTIONS
	if i == 1 then cmd.type=value
	elseif strutil.strlen(value) > 0 -- checking for nil is not enough, as we set some args to ""
	then
		if value=="-clip" or value== "-clipboard" then cmd.to_clipboard=true
		elseif value=="-osc52" then cmd.to_clipboard=true; cmd.osc52_clip=true
		elseif value=="-qr" then cmd.qr_code=true
		elseif value=="-totp" then cmd.reformat="totp"
		elseif value=="-csv" then cmd.import_type="csv"
		elseif value=="-xml" then cmd.import_type="xml"
		elseif value=="-json" then cmd.import_type="json"
		elseif value=="-zipcsv" then cmd.import_type="zip.csv"
		elseif value=="-zipxml" then cmd.import_type="zip.xml"
		elseif value=="-zipjson" then cmd.import_type="zip.json"
		elseif value=="-zcsv" then cmd.import_type="zip.csv"
		elseif value=="-zxml" then cmd.import_type="zip.xml"
		elseif value=="-zjson" then cmd.import_type="zip.json"
		elseif value=="-7zipcsv" then cmd.import_type="7zip.csv"
		elseif value=="-7zipxml" then cmd.import_type="7zip.xml"
		elseif value=="-7zipjson" then cmd.import_type="7zip.json"
		elseif value=="-7zcsv" then cmd.import_type="7zip.csv"
		elseif value=="-7zxml" then cmd.import_type="7zip.xml"
		elseif value=="-7zjson" then cmd.import_type="7zip.json"
		elseif value=="-sslcsv" then cmd.import_type="ssl.csv"
		elseif value=="-sslxml" then cmd.import_type="ssl.xml"
		elseif value=="-ssljson" then cmd.import_type="ssl.json"
		elseif value=="-scsv" then cmd.import_type="ssl.csv"
		elseif value=="-sxml" then cmd.import_type="ssl.xml"
		elseif value=="-sjson" then cmd.import_type="ssl.json"
		elseif value=="-g" or value=="-generate" then cmd.generate=32
		elseif value=="-glen" then cmd.generate=tonumber(args[i+1]); args[i+1]=""
		elseif value=="-f" then cmd.fieldlist=args[i+1]; args[i+1]=""
		elseif value=="-o" then cmd.output_path=args[i+1]; args[i+1]=""
		elseif strutil.strlen(cmd.box)==0 then cmd.box=value
		--from here on in we are treating the string not as a switch/option, but as data: paths, keynames, keyvalues, notes
		elseif cmd.type == "import" then cmd.path=value
		elseif cmd.type=="export"
		then
        if strutil.strlen(cmd.path) == 0 then cmd.path=value
        else cmd.items=cmd.items .. value..","
        end
		elseif strutil.strlen(cmd.key)==0 then cmd.key=value
		elseif strutil.strlen(cmd.value)==0 then cmd.value=value
		else cmd.notes=cmd.notes.. " "..value
		end
	end
end

		-- here we pars things into 'box' 'key' 'value' and 'notes' depending on the item type
cmd.value=strutil.trim(cmd.value)
cmd.notes=strutil.trim(cmd.notes)

if cmd.type=="export" and strutil.strlen(cmd.import_type) == 0 then cmd.import_type=DeduceFileTypeFromPath(cmd.path) end

return(cmd)
end

function OutputItemText(value, comment, cmd)
local S, str

		-- if cmd.qr_code is set, then we will write the QR code to the output path
		-- not the text output
		if cmd.qr_code == false and strutil.strlen(cmd.output_path) > 0
		then
		  S=stream.STREAM(cmd.output_path, "w")
		  if S ~= nil
		  then
		   S:writeln(value.."\n")
		   S:close()
		  end
		else
		str=value
		if strutil.strlen(comment) > 0 then str=str .. " - "..comment end
		Term:puts(str .. "\n")
		end
end


function OutputItem(item, cmd)
local value, comment

		value=item.value
		comment=item.notes

		if cmd.reformat == "totp"
		then 
			value=hash.totp("sha1", item.value, "base32", 6, 30) 
			comment="valid for: " .. string.format("%d", 30 - time.secs() % 30).." seconds"
		end

		
    OutputItemText(value, comment, cmd)
		if cmd.show_details==true
		then
		   Term:puts("updated: " .. item.updated .."\n")
		end

		if cmd.to_clipboard == true then ToClipboard(value, cmd.osc52_clip) end
		if cmd.qr_code == true then DisplayQRCode(value, cmd.output_path) end


end

function ShellCreate()
local shell={}

shell.ask=function(self, prompt, value)
local str

str=Term:prompt(prompt, value)
str=strutil.trim(str)
Term:puts("\n")

return str
end

shell.enter_item=function(self, box, key)
local item, value, notes

if strutil.strlen(key) ==0
then
  key=self:ask("key: ")
  if strutil.strlen(key) == 0 then return nil end
end

item=box:get(key)
print("GET: ["..key.."] "..tostring(item.value))

--do this so that item.value and item.notes will be nil, and thus ignored
if item == nil then item={} end

value=self:ask("value: ", item.value)
notes=self:ask("notes: ", item.notes)

return key, value, notes
end



shell.enter_data=function(self, cmd_line)
local box, key, value, notes

box=lockboxes:find(cmd_line.box)
if box ~= nil 
then
	box:load()

	key,value,notes=self:enter_item(box)
	while strutil.strlen(key) > 0
	do
	Term:puts("Adding '"..key.."'\n")
	box:add(key, value, notes)
	key,value,notes=self:enter_item(box)
	end
box:save()
end

end


shell.list=function(self, box, match)
local key, i, item
local sorted={}

 for key,item in pairs(box.items) do table.insert(sorted, key) end
 table.sort(sorted)

 for i,key in ipairs(sorted)
 do
 if match==nil or strutil.pmatch(match, string.lower(key)) == true then Term:puts(key.."\n") end
 end

end


shell.get_data=function(self, cmd, box, key)
local options={}

if cmd == "show" then options.show_details = true end
if cmd == "qr" then options.qr_code = true end
if cmd == "clip" then options.to_clipboard = true end
GetDataFromBox(box, key, options)

end

shell.cmd_loop=function(self, box)
local str, toks, cmd, key, value

str=self:ask("> ")
while str ~= nil
do
toks=strutil.TOKENIZER(str, "\\S", "Q")
cmd=toks:next()
if cmd=="quit" or cmd=="exit" then break end

if cmd=="get" then self:get_data(cmd, box, toks:remaining())
elseif cmd=="show" then self:get_data(cmd, box, toks:remaining())
elseif cmd=="qr" then self:get_data(cmd, box, toks:remaining())
elseif cmd=="clip" then self:get_data(cmd, box, toks:remaining())
elseif cmd=="add" or cmd=="set"
then
 box:add(toks:next(), toks:next(), toks:remaining())
 box:save(true)
elseif cmd=="enter"
then
    key,value,notes=self:enter_item(box, toks:remaining())
    box:add(key, value, notes)
    box:save(true)
elseif cmd=="del" or cmd=="rm" or cmd=="remove" or cmd=="delete" then
 box:remove(toks:next())
 box:save(true)
elseif cmd=="list" or cmd=="ls" then self:list(box, nil)
elseif cmd=="find" then self:list(box, string.lower(toks:next()))
elseif cmd=="help"
then
print("list         - list entries in lockbox")
print("find <pat>  - find entries matching shell-style pattern 'pat'")
print("get  <key>   - get data matching key, put to clipboard if -clip on command-line")
print("show <key>   - show data matching key, including notes, don't put to clipboard")
print("qr   <key>   - generate qr code for data associated with 'key'")
print("clip <key>   - put data for 'key' to clipboard, regardless of command-line")
print("add  <key> <data> <notes>    - add a new entry")
print("set  <key> <data> <notes>    - add a new entry, overwriting existing entry")
print("enter        - enter 'data entry' mode")
print("rm   <key>   - remove an entry")
print("del  <key>   - remove an entry")
else ui:error("Unrecognized command: ["..str.."]")
end

str=self:ask("> ")
end

end


shell.run=function(self, cmd_line)
local box, str, search, cmd

box=lockboxes:find(cmd_line.box)
if box ~= nil 
then
  if box:load() == true
  then
  self.to_clipboard=cmd_line.to_clipboard
  self:cmd_loop(box)
  else
    ui:error("failed to load/decrypt lockbox")
  end
else
  ui:error("no such lockbox")
end

end


return shell
end


function Shell(cmd)
local shell

shell=ShellCreate()
shell:run(cmd)
end
function PrintHelp()

print("treasury.lua stores key-value pairs in encrypted files called 'lockboxes'\n");
print("usage: lua treasury.lua [action] [lockbox] [key] [value]\n")
print("actions:")
print("   new [lockbox]                           create a new lockbox")
print("   list [lockbox]                          list keys in a lockbox, and comments/notes associated with them")
print("   names [lockbox]                         list keys in a lockbox")
print("   dump [lockbox]                          dump lockbox in plain text")
print("   add [lockbox] [key] [value]             add a key/value pair to a lockbox")
print("   add [lockbox] [key] -g                  generate a 32bit random string, and add it to a lockbox")
print("   add [lockbox] [key] -generate           generate a 32bit random string, and add it to a lockbox")
print("   add [lockbox] [key] -glen <len>         generate a random string, and add it to a lockbox")
print("   del [lockbox] [key]                     remove a key/value pair from a lockbox")
print("   rm  [lockbox] [key]                     remove a key/value pair from a lockbox")
print("   get [lockbox] [key]                     get the value matching 'key' in a lockbox")
print("   get [lockbox] [key] -o <path>           get the value matching 'key' in a lockbox, and write it to <path>")
print("   get [lockbox] [key] -qr                 get the value matching 'key' in a lockbox, and display as qr code")
print("   get [lockbox] [key] -qr -o <path>       get the value matching 'key' in a lockbox, and write as a qr code PNG to <path>")
print("   get [lockbox] [key] -clip               get the value matching 'key' in a lockbox, and push it to clipboard")
print("   get [lockbox] [key] -osc52              get the value matching 'key' in a lockbox, and push it to clipboard using xterm's osc52 command")
print("   get [lockbox] [key] -totp               get the value matching 'key' in a lockbox, and use it to calculate a totp code")
print("   entry [lockbox]                         enter 'data entry' mode for localbox")
print("   shell [lockbox]                         enter 'shell' mode for localbox")
print("   sync [path]                             sync key/value pairs from a lockbox file")
print("   chpw [box]                              change password for a lockbox")
print("   find [lockbox] [search pattern]         find key/value pairs matching 'search pattern'")
print("   sync [path]                             sync key/value pairs from a lockbox file")
print("   import [lockbox] [path]                 import key/value pairs from a file")
print("   export [lockbox] [path]                 export key/value pairs to a file")
print("   export [lockbox] [path] -csv            export key/value pairs from a csv file")
print("   export [lockbox] [path] -xml            export key/value pairs from a xml file")
print("   export [lockbox] [path] -json           export key/value pairs from a json file")
print("   export [lockbox] [path] -zcsv           export key/value pairs from a pkzipped csv file (with password)")
print("   export [lockbox] [path] -zxml           export key/value pairs from a pkzipped xml file (with password)")
print("   export [lockbox] [path] -zjson          export key/value pairs from a pkzipped json file (with password)")
print("   export [lockbox] [path] -7zcsv          export key/value pairs from a 7zipped csv file (with password)")
print("   export [lockbox] [path] -7zxml          export key/value pairs from a 7zipped xml file (with password)")
print("   export [lockbox] [path] -7zjson         export key/value pairs from a 7zipped json file (with password)")
print("   show-config                             print out application config")
print("   config-set [name] [value]               change a config value")
print("   version                                 print program version")
print("   -version                                print program version")
print("   --version                               print program version")
print("   --help                                  print help")
print("   -help                                   print help")
print("   help                                    print help")
print("   -?                                      print help")

print("")
print("The type of file for import and export can be set using the -csv, -xml, -json, -zcsv, -zxml, -zjson, -7zcsv, -7zxml, -7zjson, -scsv, -sxml, -sjson options. Without these the import and export commands will try to guess the filetype.")
print("The import command examines the file at [path] and can open csv, xml and json files, including those that have been packaged/encrypted with pkzip/infozip, 7zip, or simply encrypted with openssl.");
print("The export command uses the extension of the supplied filename to guess the filetype. Thus extensions should be in the form .csv, .zcsv, .7zscv .scsv");
end



Mode="cli"
Version="1.7"


function NewLockbox(cmd)
local name

name=cmd.box
if strutil.strlen(name) == 0 then name=ui:query_bar("Name: ")  end

if strutil.strlen(name) > 0 
then 
	box=lockboxes:find(name)
	if box ~= nil 
	then 
		str=ui:query_bar("~rLockbox '"..name.."' already exists! Overwrite?  ")
		if str ~= "y" then return end
	end

	pass,hint=ui:ask_lockbox_details()
	Term:puts("\nSetting up new lockbox\n")
	box=lockboxes:new(name, pass, hint)
	box:save()
	return box
end
return nil
end


function ChangePassword(cmd)
local box, item

box=lockboxes:find(cmd.box)
if box ~= nil
then
	if box:load() == true
	then
	box.password,box.passhint=ui:ask_lockbox_details("New Password for Lockbox:")
	box:save()
	else ui:error("incorrect password")
	end
else ui:error_no_lockbox(cmd.box)
end

end


function Rebuild(cmd)
local box, item

box=lockboxes:find(cmd.box)
if box ~= nil
then
	if box:load() == true then box:save()
	else ui:error("incorrect password")
	end
else ui:error_no_lockbox(cmd.box)
end

end



function DepositData(cmd)
local path, str, S

if cmd.generate > 0
then
cmd.value=entropy.get(cmd.generate)
print("generated value: "..cmd.value)
end

if strutil.strlen(cmd.value) ~= 0 
then 
	lockboxes:deposit(cmd.box, cmd.key, cmd.value, cmd.notes)
else
	str=EditorLaunch()
  if strutil.strlen(str) > 0 
  then
    lockboxes:deposit(cmd.box, cmd.key, str)
  end
end

end



function RemoveData(cmd)
local box, item

box=lockboxes:find(cmd.box)
if box ~= nil
then
	if box:load() == true
	then 
	box:remove(cmd.key)
	box:save()
	else ui:error("incorrect password")
	end
else ui:error_no_lockbox(cmd.box)
end


end


function DumpData(cmd)
local str

str=lockboxes:read(cmd.box)
if str==nil then ui:error("incorrect password")
-- use print not Term:puts to prevent interpretation of characters in the dump
else print(str)
end

end




function GetDataFromBox(box, key, cmd)
local item

	item=box:get(key)
	Term:puts("\n")
	if item ~= nil 
	then 
    OutputItem(item, cmd)
	else 
    ui:error("key not found in lockbox")
	end
end


function GetData(cmd)
local box, item

box=lockboxes:find(cmd.box)
if box ~= nil
then
	if box:load() == true
	then GetDataFromBox(box, cmd.key, cmd)
	else ui:error("incorrect password")
	end
else ui:error_no_lockbox(cmd.box)
end

end


function FindData(cmd)
local box, str

box=lockboxes:find(cmd.box)
if box ~= nil
then
	box:load()

	for key,value in pairs(box.items)
	do
		if strutil.pmatch(cmd.key, key) == true 
		then
			item=box:get(key)
			Term:puts(item.value.."\n")
		end
	end
else ui:error_no_lockbox(cmd.box)
end

end


function ListLockboxes(cmd)
local list

list=lockboxes:list()
for i,item in pairs(list)
do
	print(item)
end

end



function ListLockboxContents(cmd)
local box, key, item, str


box=lockboxes:find(cmd.box)
if box ~= nil 
then
	box:load()
	for key,item in pairs(box.items)
	do
		if cmd.type == "names" then Term:puts(key.."\n")
		else 
			str=key
			if strutil.strlen(item.notes) > 0 then str=strutil.padto(str, ' ', 30) .." "..string.sub(item.notes,1,Term:width() - 32) end
			Term:puts(str.."\n")
		end	
	end
else ui:error_no_lockbox(cmd.box)
end

end


function ListLockbox(cmd)

if strutil.strlen(cmd.box) == 0
then
  ListLockboxes(cmd)
else
  ListLockboxContents(cmd)
end

end




function ImportData(cmd)
local S, str, toks

if strutil.strlen(cmd.path) == 0
then
ui:error("import command must have format: treasury.lua import <lockbox> <import path>")
return
end

box=lockboxes:find(cmd.box)
if box == nil then box=NewLockbox(cmd) end
importer:import(box, cmd.path, cmd.fieldlist, cmd.import_type)

end



function SyncData(cmd_line)
local i

for i=2,#cmd_line,1
do
if lockboxes:sync(cmd_line[i]) ~= true then ui:error("incorrect password") end
end
end




function TreasuryInit()
local str=""


--setup config
config=ConfigInit()

--configure settings for this process. This will involve stuff like disabling
--coredumps to prevent leaving sensitive data on disk

--openlog here causes strange issues in syslog. I think it's down to lua garbage collection,
--but haven't figured it out yet
--str="openlog=treasury.lua "

if config.coredumps==false then str=str.."coredumps=0 " end
if config.mlock==true then str=str.."mlock " end
if config.resist_strace==true then str=str.."resist_strace " end
process.configure(str)

--next setup the terminal. We do this early as other functions need a terminal to write to
ui=UI_Init()
Term=terminal.TERM(nil, "wheelmouse rawkeys save")

--setup the 'lockboxes' system that actually stores our data
lockboxes=InitLockboxes()
--setup the system for syncing data between hosts
sync=SyncInit()
--setup the system for storing information about hosts 
--that is used in syncing
hosts=HostsInit()

end




TreasuryInit()
cmd=CommandLineParse(arg)


if cmd.type == "new" then NewLockbox(cmd)
elseif cmd.type == "add" or cmd.type=="set" then DepositData(cmd)
elseif cmd.type == "del" or cmd.type=="rm" then RemoveData(cmd)
elseif cmd.type == "entry" then EnterData(cmd)
elseif cmd.type == "list" or cmd.type == "ls" or cmd.type=="names" then ListLockbox(cmd)
elseif cmd.type == "get"  then GetData(cmd)
elseif cmd.type == "find"  then FindData(cmd)
elseif cmd.type == "dump" then DumpData(cmd)
elseif cmd.type == "import" then ImportData(cmd)
elseif cmd.type == "sync" then SyncData(arg)
elseif cmd.type == "push" then lockboxes:sync_push()
elseif cmd.type == "export" then exporter:export(cmd)
elseif cmd.type == "show-config" then config:output()
elseif cmd.type == "config-set" then config:change(arg[2], arg[3])
elseif cmd.type == "shell" then Shell(cmd)
elseif cmd.type == "chpw" then ChangePassword(cmd)
elseif cmd.type == "rebuild" then Rebuild(cmd)
elseif cmd.type == "version" or cmd.type == "-version" or cmd.type == "--version" then print("treasury.lua "..Version)
elseif cmd.type == "--help" or cmd.type == "-help" or cmd.type == "help" or cmd.type == "-?" then PrintHelp()
else
PrintHelp()
end

Term:flush()
Term:reset()

