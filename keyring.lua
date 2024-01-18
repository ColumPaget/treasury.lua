keyring={}

keyring.set=function(self, lockbox_name, password)
local S, str

S=stream.STREAM("cmd:keyctl padd user 'treasury.lua:"..lockbox_name.."' @u","")
if S ~= nil
then
S:writeln(password.."\r\n")
S:commit()
str=S:readln()
S:close()
end

end



keyring.get=function(self, lockbox_name)
local S, str

S=stream.STREAM("cmd:keyctl search @u user 'treasury.lua:"..lockbox_name.."'","rw stderr2null")
if S ~= nil
then
str=S:readln()
S:close()
end

if strutil.strlen(str) > 0
then
  S=stream.STREAM("cmd:keyctl pipe "..str,"rw stderr2null")
  if S ~= nil
  then
     str=strutil.trim(S:readln())
     S:close()
  end
end

return str
end
