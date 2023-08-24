
function ShellCreate()
local shell={}

shell.ask=function(self, prompt, value)
local str

str=Term:prompt(prompt, value)
str=strutil.trim(str)
Term:puts("\n")

return str
end

shell.enter_item=function(self, box, key)
local item, value, notes

if strutil.strlen(key) ==0
then
  key=self:ask("key: ")
  if strutil.strlen(key) == 0 then return nil end
end

item=box:get(key)
print("GET: ["..key.."] "..tostring(item.value))

--do this so that item.value and item.notes will be nil, and thus ignored
if item == nil then item={} end

value=self:ask("value: ", item.value)
notes=self:ask("notes: ", item.notes)

return key, value, notes
end



shell.enter_data=function(self, cmd_line)
local box, key, value, notes

box=lockboxes:find(cmd_line.box)
if box ~= nil 
then
	box:load()

	key,value,notes=self:enter_item(box)
	while strutil.strlen(key) > 0
	do
	Term:puts("Adding '"..key.."'\n")
	box:add(key, value, notes)
	key,value,notes=self:enter_item(box)
	end
box:save()
end

end


shell.list=function(self, box, match)
local key, i, item
local sorted={}

 for key,item in pairs(box.items) do table.insert(sorted, key) end
 table.sort(sorted)

 for i,key in ipairs(sorted)
 do
 if match==nil or strutil.pmatch(match, string.lower(key)) == true then Term:puts(key.."\n") end
 end

end


shell.cmd_loop=function(self, box)
local str, toks, cmd, key, value

str=self:ask("> ")
while str ~= nil
do
toks=strutil.TOKENIZER(str, "\\S", "Q")
cmd=toks:next()
if cmd=="quit" or cmd=="exit" then break end

if cmd=="get" then GetDataFromBox(box, toks:remaining(), false, self.to_clipboard, false)
elseif cmd=="show" then GetDataFromBox(box, toks:remaining(), true, false, false)
elseif cmd=="qr" then GetDataFromBox(box, toks:remaining(), false, false, true)
elseif cmd=="clip" then GetDataFromBox(box, toks:remaining(), false, true, false)
elseif cmd=="add" or cmd=="set"
then
 box:add(toks:next(), toks:next(), toks:remaining())
 box:save(true)
elseif cmd=="enter"
then
    key,value,notes=self:enter_item(box, toks:remaining())
    box:add(key, value, notes)
    box:save(true)
elseif cmd=="del" or cmd=="rm" or cmd=="remove" or cmd=="delete" then
 box:remove(toks:next())
 box:save(true)
elseif cmd=="list" or cmd=="ls" then self:list(box, nil)
elseif cmd=="find" then self:list(box, string.lower(toks:next()))
elseif cmd=="help"
then
print("list         - list entries in lockbox")
print("find <pat>  - find entries matching shell-style pattern 'pat'")
print("get  <key>   - get data matching key, put to clipboard if -clip on command-line")
print("show <key>   - show data matching key, including notes, don't put to clipboard")
print("qr   <key>   - generate qr code for data associated with 'key'")
print("clip <key>   - put data for 'key' to clipboard, regardless of command-line")
print("add  <key> <data> <notes>    - add a new entry")
print("set  <key> <data> <notes>    - add a new entry, overwriting existing entry")
print("enter        - enter 'data entry' mode")
print("rm   <key>   - remove an entry")
print("del  <key>   - remove an entry")
else ErrorMsg("Unrecognized command: ["..str.."]")
end

str=self:ask("> ")
end

end


shell.run=function(self, cmd_line)
local box, str, search, cmd

box=lockboxes:find(cmd_line.box)
if box ~= nil 
then
  if box:load() == true
  then
  self.to_clipboard=cmd_line.to_clipboard
  self:cmd_loop(box)
  else
    ErrorMsg("failed to load/decrypt lockbox")
  end
else
  ErrorMsg("no such lockbox")
end

end


return shell
end


function Shell(cmd)
local shell

shell=ShellCreate()
shell:run(cmd)
end
