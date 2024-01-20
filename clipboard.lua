
function FindClipboardCmd()
local toks, tok, cmd

str=FindCmd(config:get("clip_cmd"))
if strutil.strlen(str)==0 then return "xterm" end
return str
end


function RunClipboardCmd(cmd, text)
local proc, S

  proc=process.PROCESS(cmd)
  if proc ~= nil
  then
	S=proc:get_stream()
	if S ~= nil
	then
		S:writeln(text)
		proc:wait_exit();
	end
  end
end


function ToClipboard(text, use_osc52)
local cmd

cmd=FindClipboardCmd()

if use_osc52 == true
then
	Term:xterm_set_clipboard(text)
elseif strutil.strlen(cmd) > 0
then
   if cmd == "xterm" then Term:xterm_set_clipboard(text)
   else RunClipboardCmd(cmd, text)
   end
end

end
