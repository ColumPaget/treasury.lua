function DisplayLockboxItem(box, key)
local value, str, Menu

Term:clear()
TitleBar("~B~wContents of '"..box.name..":"..key.."'")

Menu=terminal.TERMMENU(Term, 1, 2, Term:width() -2, 4)
Menu:add("to clipboard", "clipboard")
Menu:add("display as qrcode", "qrcode")
Menu:add("view in editor", "view")
Menu:add("delete item", "delete")

Term:move(0,8)
item=box:get(key)
Term:puts(item.value)

str=Menu:run()
if strutil.strlen(str) > 0
then
	if str=="clipboard" then ToClipboard(value)
	elseif str=="qrcode" then DisplayQRCode(value)
	elseif str=="delete" then 
		box:remove(key)
		box:save()
	end
end

end


function DisplayLockbox(Menu, name)
local box, key, value, str

box=lockboxes:find(name)
if box:load() ~= true 
then
 ErrorMsg("incorrect password.")
 box.password=nil
 return false 
end

while true
do
Term:clear()
Menu:clear()
TitleBar("~B~wLockbox: '"..box.name.."'")

Menu:add("Add new item", "add")
Menu:add("Add new item with editor", "add-editor")
for key,value in pairs(box.items)
do
	Menu:add(key)
end

str=Menu:run()
if strutil.strlen(str) > 0 
then 
	if str=="add" then QueryNewItem(box)
	elseif str=="add-editor" then QueryNewItemWithEditor(box)
	else
		DisplayLockboxItem(box, str) 
  end
else break
end
end

return true
end


function MainMenuRefresh(Menu)
local  item

Menu:clear()
Menu:add("New Lockbox", "new")
item=lockboxes:first()
while item ~= nil
do
Menu:add(item.name, item.name)
item=lockboxes:next()
end

end


function MainScreen()
local Menu, item

Mode="menu"
Term:clear()
Term:move(0,0)

Menu=terminal.TERMMENU(Term, 1,2,Term:width() -2, Term:height() -4)

while true
do
MainMenuRefresh(Menu)
item=Menu:run()

if strutil.strlen(item) == 0 then break
elseif item=="new" then NewLockbox()
else DisplayLockbox(Menu, item)
end
 
end

end


