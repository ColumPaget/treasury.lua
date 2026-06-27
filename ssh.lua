function SSHRunCommand(cmd, url, dest)
local S, toks, server, path, dest_path, str

toks=strutil.TOKENIZER(url, "/")
server=toks:next()
path=toks:remaining()

str=server .. "/" .. cmd .. " " .. path
if strutil.strlen(dest) > 0 
then 
  toks=strutil.TOKENIZER(dest, "/")
  server=toks:next()
  dest_path=toks:remaining()
  str=str.." "..dest_path 
end

if GlobalDebug == true then io.stderr:write("SSHRunCommand: ".. str.."\n") end

S=stream.STREAM(str, "x")
if S ~= nil
then
  str=S:readdoc()
  print(str)
  S:close()
end

end
