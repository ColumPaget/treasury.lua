
function DisplayQRCode(value, output_path)
local S, str, path, cmd

if strutil.strlen(output_path) > 0 then path=output_path
else path="/tmp/.treasury_qrcode.png"
end

cmd=FindCmd(config:get("qr_cmd"))
if cmd ~= nil
then
S=stream.STREAM("cmd:" .. cmd .. " " .. path)
if S ~= nil
then
	S:writeln(value)
	S:commit()
	str=S:readln()
	S:close()

  -- if output_path is set, then we just write the png file to that path,
	-- we don't display it, and we don't scrub/delete the file
	if strutil.strlen(output_path) ==0
	then
  	cmd=FindCmd(config:get("iview_cmd"))
  	if cmd ~= nil then os.execute(cmd .. " " .. path) end
  	ScrubFile(path)
	end

end
end


end
