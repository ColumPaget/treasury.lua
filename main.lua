Mode="cli"
Version="1.6"


function NewLockbox(cmd)
local name

name=cmd.box
if strutil.strlen(name) == 0 then name=ui:query_bar("Name: ")  end

if strutil.strlen(name) > 0 
then 
	box=lockboxes:find(name)
	if box ~= nil 
	then 
		str=ui:query_bar("~rLockbox '"..name.."' already exists! Overwrite?  ")
		if str ~= "y" then return end
	end

	pass,hint=ui:ask_lockbox_details()
	Term:puts("\nSetting up new lockbox\n")
	box=lockboxes:new(name, pass, hint)
	box:save()
	return box
end
return nil
end


function ChangePassword(cmd)
local box, item

box=lockboxes:find(cmd.box)
if box ~= nil
then
	if box:load() == true
	then
	box.password,box.passhint=ui:ask_lockbox_details("New Password for Lockbox:")
	box:save()
	else ui:error("incorrect password")
	end
else ui:error_no_lockbox(cmd.box)
end

end


function Rebuild(cmd)
local box, item

box=lockboxes:find(cmd.box)
if box ~= nil
then
	if box:load() == true then box:save()
	else ui:error("incorrect password")
	end
else ui:error_no_lockbox(cmd.box)
end

end



function DepositData(cmd)
local path, str, S

if cmd.generate > 0
then
cmd.value=entropy.get(cmd.generate)
print("generated value: "..cmd.value)
end

if strutil.strlen(cmd.value) ~= 0 
then 
	lockboxes:deposit(cmd.box, cmd.key, cmd.value, cmd.notes)
else
	str=EditorLaunch()
  if strutil.strlen(str) > 0 
  then
    lockboxes:deposit(cmd.box, cmd.key, str)
  end
end

end


function DumpData(cmd)
local str

str=lockboxes:read(cmd.box)
if str==nil then ui:error("incorrect password")
-- use print not Term:puts to prevent interpretation of characters in the dump
else print(str)
end

end




function GetDataFromBox(box, key, cmd)
local item

	item=box:get(key)
	Term:puts("\n")
	if item ~= nil 
	then 

		if strutil.strlen(cmd.output_path) > 0
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

		if cmd.to_clipboard == true then ToClipboard(item.value, cmd.osc52_clip) end
		if cmd.qr_code == true then DisplayQRCode(item.value) end
		if cmd.show_details==true
		then
		   Term:puts("updated: " .. item.updated .."\n")
		   Term:puts("notes: ".. item.notes .."\n")
		end
	else ui:error("key not found in lockbox")
	end
end


function GetData(cmd)
local box, item

box=lockboxes:find(cmd.box)
if box ~= nil
then
	if box:load() == true
	then GetDataFromBox(box, cmd.key, cmd)
	else ui:error("incorrect password")
	end
else ui:error_no_lockbox(cmd.box)
end

end


function FindData(cmd)
local box, str

box=lockboxes:find(cmd.box)
if box ~= nil
then
	box:load()

	for key,value in pairs(box.items)
	do
		if strutil.pmatch(cmd.key, key) == true 
		then
			item=box:get(key)
			Term:puts(item.value.."\n")
		end
	end
else ui:error_no_lockbox(cmd.box)
end

end


function ListLockboxes(cmd)
local list

list=lockboxes:list()
for i,item in pairs(list)
do
	print(item)
end

end



function ListLockboxContents(cmd)
local box, key, value

box=lockboxes:find(cmd.box)
if box ~= nil 
then
	box:load()
	for key,value in pairs(box.items)
	do
		Term:puts(key.."\n")
	end
else ui:error_no_lockbox(cmd.box)
end

end

function ListLockbox(cmd)

if strutil.strlen(cmd.box) == 0
then
  ListLockboxes(cmd)
else
  ListLockboxContents(cmd)
end

end




function ImportData(cmd)
local S, str, toks

if strutil.strlen(cmd.path) == 0
then
ui:error("import command must have format: treasury.lua import <lockbox> <import path>")
return
end

box=lockboxes:find(cmd.box)
if box == nil then box=NewLockbox(cmd) end
importer:import(box, cmd.path, cmd.fieldlist, cmd.import_type)

end



function SyncData(cmd_line)
local i

for i=2,#cmd_line,1
do
if lockboxes:sync(cmd_line[i]) ~= true then ui:error("incorrect password") end
end
end




function TreasuryInit()
local str=""


--setup config
config=ConfigInit()

--configure settings for this process. This will involve stuff like disabling
--coredumps to prevent leaving sensitive data on disk

--openlog here causes strange issues in syslog. I think it's down to lua garbage collection,
--but haven't figured it out yet
--str="openlog=treasury.lua "

if config.coredumps==false then str=str.."coredumps=0 " end
if config.mlock==true then str=str.."mlock " end
if config.resist_strace==true then str=str.."resist_strace " end
process.configure(str)

--next setup the terminal. We do this early as other functions need a terminal to write to
ui=UI_Init()
Term=terminal.TERM(nil, "wheelmouse rawkeys save")

--setup the 'lockboxes' system that actually stores our data
lockboxes=InitLockboxes()
--setup the system for syncing data between hosts
sync=SyncInit()
--setup the system for storing information about hosts 
--that is used in syncing
hosts=HostsInit()

end




TreasuryInit()
cmd=CommandLineParse(arg)


if cmd.type == "new" then NewLockbox(cmd)
elseif cmd.type == "add" or cmd.type=="set" then DepositData(cmd)
elseif cmd.type == "entry" then EnterData(cmd)
elseif cmd.type == "list" or type == "ls" then ListLockbox(cmd)
elseif cmd.type == "get"  then GetData(cmd)
elseif cmd.type == "find"  then FindData(cmd)
elseif cmd.type == "dump" then DumpData(cmd)
elseif cmd.type == "import" then ImportData(cmd)
elseif cmd.type == "sync" then SyncData(arg)
elseif cmd.type == "push" then lockboxes:sync_push()
elseif cmd.type == "export" then exporter:export(cmd)
elseif cmd.type == "show-config" then config:output()
elseif cmd.type == "config-set" then config:change(arg[2], arg[3])
elseif cmd.type == "shell" then Shell(cmd)
elseif cmd.type == "chpw" then ChangePassword(cmd)
elseif cmd.type == "rebuild" then Rebuild(cmd)
elseif cmd.type == "version" or cmd.type == "-version" or cmd.type == "--version" then print("treasury.lua "..Version)
elseif cmd.type == "--help" or cmd.type == "-help" or cmd.type == "help" or cmd.type == "-?" then PrintHelp()
else
PrintHelp()
end

Term:flush()
Term:reset()

