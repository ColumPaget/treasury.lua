
function FindClipboardCmd()
local toks, tok, cmd

str=FindCmd(config:get("clip_cmd"))
if strutil.strlen(str)==0 then return "xterm" end
return str
end


function RunClipboardCmd(cmd, text)
local proc, S

  if GlobalDebug == true then io.stderr:write("RunClipboardCmd: "..tostring(cmd) .. "\n") end
  proc=process.PROCESS(cmd)
  if proc ~= nil
  then
	S=proc:get_stream()
	if S ~= nil
	then
  		if GlobalDebug == true then io.stderr:write("ClipboardCmd SendText: "..tostring(text) .. "\n") end
		S:writeln(text.."\n")
		S:commit()
		proc:wait_exit();
	end
  end
end


function ToClipboard(text, use_osc52)
local cmd

cmd=FindClipboardCmd()

-- if use_osc52 is set it means 'force use of xterm sequences to set clipboard'
if use_osc52 == true
then
  if GlobalDebug == true then io.stderr:write("xterm-clipboard send: "..tostring(text) .. "\n") end
  Term:xterm_set_clipboard(text)
elseif strutil.strlen(cmd) > 0
then
   -- if we didn't find a command to use, we will fall back to 'xterm'
   if cmd == "xterm" 
   then 
      if GlobalDebug == true then io.stderr:write("xterm-clipboard send: "..tostring(text) .. "\n") end
      Term:xterm_set_clipboard(text)
   else 
    RunClipboardCmd(cmd, text)
   end
end

end
