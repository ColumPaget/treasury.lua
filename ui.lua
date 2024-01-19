function UI_Init()
local ui={}


ui.title_bar=function(self, text)
Term:move(0,0)
Term:puts(text.."~>~0")
end



ui.error=function(self, msg)
local str

if msg==nil then msg="" end

if Mode=="menu"
then
	Term:move(0, Term:height() -1)
	str=Term:puts("~R~w"..msg.."~>")
	Term:puts("~0")
else
	str=terminal.format("~r~eERROR: "..msg.."~0\n")
	io.stderr:write(str)
end

return str
end


ui.error_no_lockbox=function(self, box)
self:error("no such lockbox '"..box.."' for user '"..process.user().."'")
end


ui.query_bar=function(self, prompt)
local str

if Mode=="menu"
then
Term:move(0, Term:height() -1)
str=Term:prompt("~B~w"..prompt.."~>")
Term:puts("~0")
else
str=Term:prompt(prompt.."~>")
Term:puts("~0\n")
end

return str
end


ui.ask_lockbox_details=function(self, prompt)
local pass, hint

if prompt == nil then prompt="Password for new lockbox:" end
pass=Term:prompt(prompt, config:get("pass_hide"))
Term:puts("\n")

if strutil.strlen(pass) > 0 then hint=ui:query_bar("Password hint (leave blank for none):" ) end

return pass, hint
end



ui.ask_password=function(self, prompt, hint)
local str

if Mode=="menu"
then
Term:move(0, Term:height() -2)
if strutil.strlen(hint) > 0 then Term:puts("Password hint: "..hint.."\n") end
str=Term:prompt("~B~w"..prompt.."~>", config:get("pass_hide"))
Term:puts("~0")
else
if strutil.strlen(hint) > 0 then Term:puts("Password hint: "..hint.."\n") end
str=Term:prompt(prompt.."~>", config:get("pass_hide"))
Term:puts("~0\n")
end

return str
end



ui.new_item=function(self, box)
local key, value

key=ui:query_bar("Enter name/key for new item: ")
value=ui:query_bar("Enter value for new item: ")

box:add(key, value)
box:save()
end



ui.new_item_editor=function(self, box)
local key, value

key=ui:query_bar("Enter name/key for new item: ")
value=EditorLaunch()

box:add(key, value)
box:save()
end


return(ui)
end
