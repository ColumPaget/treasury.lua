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
