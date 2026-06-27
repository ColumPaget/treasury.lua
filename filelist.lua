

--this is a function that turns a comma-separated list of patterns into a list of files
--with support for doing that over ssh


function get_filelist_ssh(files, pattern)
local S, str, path

S=stream.STREAM(pattern, "l")
if S ~= nil
then
  str=S:readln()
  while str ~= ni
  do
  str=strutil.trim(str)
  path=filesys.dirname(pattern) .. "/" .. filesys.basename(str)
  table.insert(files, path)
  str=S:readln()
  end
  S:close()
end

end

function get_filelist_glob(files, pattern)
local glob, path

glob=filesys.GLOB(pattern)
path=glob:next()
while path ~= nil
do
table.insert(files, path)
path=glob:next()
end

end

function get_filelist(patterns)
local toks, pattern
local files={}

toks=strutil.TOKENIZER(patterns, ",", "Q")
pattern=toks:next()
while pattern ~= nil
do
pattern=strutil.trim(pattern)
if string.sub(pattern, 1, 4) == "ssh:" then get_filelist_ssh(files, pattern) 
else get_filelist_glob(files, pattern)
end
pattern=toks:next()
end

return files
end
