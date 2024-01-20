
function OutputItemText(value, comment, cmd)
local S, str

		-- if cmd.qr_code is set, then we will write the QR code to the output path
		-- not the text output
		if cmd.qr_code == false and strutil.strlen(cmd.output_path) > 0
		then
		  S=stream.STREAM(cmd.output_path, "w")
		  if S ~= nil
		  then
		   S:writeln(value.."\n")
		   S:close()
		  end
		else
		str=value
		if strutil.strlen(comment) > 0 then str=str .. " - "..comment end
		Term:puts(str .. "\n")
		end
end


function OutputItem(item, cmd)
local value, comment

		value=item.value
		comment=item.notes

		if cmd.reformat == "totp"
		then 
			value=hash.totp("sha1", item.value, "base32", 6, 30) 
			comment="valid for: " .. string.format("%d", 30 - time.secs() % 30).." seconds"
		end

		
    OutputItemText(value, comment, cmd)
		if cmd.show_details==true
		then
		   Term:puts("updated: " .. item.updated .."\n")
		end

		if cmd.to_clipboard == true then ToClipboard(value, cmd.osc52_clip) end
		if cmd.qr_code == true then DisplayQRCode(value, cmd.output_path) end


end
