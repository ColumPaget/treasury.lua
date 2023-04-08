function EditorLaunch()
local path, S, str, cmd

	cmd=FindCmd(config:get("edit_cmd"))
	if cmd==nil then return nil end

	path=process.getenv("HOME") .. "/.treasury/" .. tostring(process.pid()) .. ".data"
	os.execute(cmd.." "..path)

	str=""
	S=stream.STREAM(path, "r")
	if S ~= nil
	then
	str=S:readdoc()
	S:close()
	ScrubFile(path)
	end

	return(str)
end

