
function FindExecutable(cmd)
local toks, tok, prog, path

toks=strutil.TOKENIZER(cmd, "\\S")
tok=toks:next()
path=filesys.find(tok, process.getenv("PATH"))
if strutil.strlen(path) > 0 
then 
tok=toks:remaining()
if strutil.strlen(tok) > 0 then path=path .. " " .. tok end
return(path)
end

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


