function ErrorMsg(msg)
local str

if Mode=="menu"
then
	Term:move(0, Term:height() -1)
	str=Term:puts("~R~w"..msg.."~>")
	Term:puts("~0")
else
	str=Term:puts("~r~eERROR: "..msg)
	Term:puts("~0\n")
end

return str
end



function QueryBar(prompt)
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


function QueryNewLockboxDetails(prompt)
local pass, hint

if prompt == nil then prompt="Password for new lockbox:" end
pass=Term:prompt(prompt, config:get("pass_hide"))
Term:puts("\n")

if strutil.strlen(pass) > 0 then hint=QueryBar("Password hint (leave blank for none):" ) end

return pass, hint
end



function QueryPassword(prompt, hint)
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



function QueryNewItem(box)
local key, value

key=QueryBar("Enter name/key for new item: ")
value=QueryBar("Enter value for new item: ")

box:add(key, value)
box:save()
end



function QueryNewItemWithEditor(box)
local key, value

key=QueryBar("Enter name/key for new item: ")
value=EditorLaunch()

box:add(key, value)
box:save()
end



function TitleBar(text)
Term:move(0,0)
Term:puts(text.."~>~0")
end

