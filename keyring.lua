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




