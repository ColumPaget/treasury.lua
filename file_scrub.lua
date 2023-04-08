
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
	ErrorMsg("failed to scrub/overwrite: ".. path)
end

end

filesys.unlink(path)
if filesys.exists(path) == true then ErrorMsg("failed to delete: ".. path) end
end
