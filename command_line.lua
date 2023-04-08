function CommandLineParse(args)
local cmd={}

cmd.to_clipboard=false
cmd.osc52_clip=false
cmd.qr_code=false
cmd.csv=false
cmd.json=false
cmd.value=""
cmd.fieldlist=""
cmd.items=""
cmd.generate=0

for i,value in ipairs(args)
do
	if i == 1 then cmd.type=value
	elseif strutil.strlen(value) > 0 -- checking for nil is not enough, as we set some args to ""
	then
		if value=="-clip" or value== "-clipboard" then cmd.to_clipboard=true
		elseif value=="-osc52" then cmd.to_clipboard=true; cmd.osc52_clip=true
		elseif value=="-qr" then cmd.qr_code=true
		elseif value=="-csv" then cmd.import_type="csv"
		elseif value=="-xml" then cmd.import_type="xml"
		elseif value=="-json" then cmd.import_type="json"
		elseif value=="-zipcsv" then cmd.import_type="zip.csv"
		elseif value=="-zipxml" then cmd.import_type="zip.xml"
		elseif value=="-zipjson" then cmd.import_type="zip.json"
		elseif value=="-zcsv" then cmd.import_type="zip.csv"
		elseif value=="-zxml" then cmd.import_type="zip.xml"
		elseif value=="-zjson" then cmd.import_type="zip.json"
		elseif value=="-7zipcsv" then cmd.import_type="7zip.csv"
		elseif value=="-7zipxml" then cmd.import_type="7zip.xml"
		elseif value=="-7zipjson" then cmd.import_type="7zip.json"
		elseif value=="-sslcsv" then cmd.import_type="ssl.csv"
		elseif value=="-sslxml" then cmd.import_type="ssl.xml"
		elseif value=="-ssljson" then cmd.import_type="ssl.json"
		elseif value=="-g" or value=="-generate" then cmd.generate=32
		elseif value=="-glen" then cmd.generate=tonumber(args[i+1]); args[i+1]=""
		elseif value=="-f" then cmd.fieldlist=args[i+1]; args[i+1]=""
		elseif strutil.strlen(cmd.box)==0 then cmd.box=value
		else
			if cmd.type == "import" 
			then 
			cmd.path=value
			elseif cmd.type=="export"
			then
			  if strutil.strlen(cmd.path) == 0 then cmd.path=value
			  else cmd.items=cmd.items .. value..","
                          end
			elseif strutil.strlen(cmd.key)==0 then cmd.key=value
			else cmd.value=cmd.value .. value .." "
			end
		end
	end
end

strutil.trim(cmd.value)

return(cmd)
end
