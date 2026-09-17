
lockbox_passwords={}
lockbox_passwords.items={}


lockbox_passwords.add=function(self, name, value)

self.items[name]=value


end


lockbox_passwords.get=function(self, name, hint)
local queried_password=false
local pass

if strutil.strlen(self.items[name]) > 0 then return self.items[name] end

pass=keyring:get(name)
if GlobalDebug == true then io.stderr:write("Using keyring: got "..tostring(pass).."\n") end


if strutil.strlen(pass) == 0
then
  pass=ui:ask_password("Password for "..name..": ~>", hint)
  queried_password=true
end

self:add(name, pass)

-- we cannot do this here, because we do not know that the password is correct. We can only do this after successfully
-- opening a lockbox file
-- if queried_password == true and strutil.strlen(pass) > 0 and config:get("keyring") ~= "n" then keyring:set(name, pass) end


return pass,queried_password
end


