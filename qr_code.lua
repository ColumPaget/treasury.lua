
function QRCodeCreate(value, path, args)
local cmd, S, str

cmd=FindCmd("qrencode")
if cmd ~= nil
then
	str="cmd:" .. cmd 
	if strutil.strlen(path) > 0 then str=str .. " -o " .. path end
	if strutil.strlen(args) > 0 then str=str .. " " ..args end

  S=stream.STREAM(str)
  if S ~= nil
  then
  	S:writeln(value)
  	S:commit()
  	str=S:readdoc()
		print(str)
  	S:close()
  end
end

end



function DisplayQRCode(value, output_path)
local S, str, path, cmd, viewer

if strutil.strlen(output_path) > 0 then path=output_path
else path="/tmp/.treasury_qrcode.png"
end

viewer=FindCmd(config:get("iview_cmd"))

if strutil.strlen(viewer) == 0 then QRCodeCreate(value, "-", " -t ANSI256")
else QRCodeCreate(value, path)
end

-- if output_path is set, then we just write the png file to that path,
-- we don't display it, and we don't scrub/delete the file
if strutil.strlen(output_path) ==0 and strutil.strlen(viewer) > 0
then
  str=viewer .. " " .. path
  if viewer=="convert" then str=str.." sixel:-" end 

 	if viewer ~= nil then os.execute(str) end
 	ScrubFile(path)
end

end


