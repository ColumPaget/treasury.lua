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
