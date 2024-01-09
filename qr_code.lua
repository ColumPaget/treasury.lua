
function DisplayQRCode(value)
local S, str, path, cmd

path="/tmp/.treasury_qrcode.png"

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

	cmd=FindCmd(config:get("iview_cmd"))
	if cmd ~= nil then os.execute(cmd .. " " .. path) end
	ScrubFile(path)
end
end


end
