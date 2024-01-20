
function OutputItemText(item, cmd)
local S

		-- if cmd.qr_code is set, then we will write the QR code to the output path
		-- not the text output
		if cmd.qr_code == false and strutil.strlen(cmd.output_path) > 0
		then
		  S=stream.STREAM(cmd.output_path, "w")
		  if S ~= nil
		  then
		   S:writeln(item.value.."\n")
		   S:close()
		  end
		else
		Term:puts(item.value .. "\n")
		end
end


function OutputItem(item, cmd)

		if cmd.to_clipboard == true then ToClipboard(item.value, cmd.osc52_clip) end
		if cmd.qr_code == true then DisplayQRCode(item.value, cmd.output_path) end

    OutputItemText(item, cmd)
		if cmd.show_details==true
		then
		   Term:puts("updated: " .. item.updated .."\n")
		   Term:puts("notes: ".. item.notes .."\n")
		end

end
