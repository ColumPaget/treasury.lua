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
