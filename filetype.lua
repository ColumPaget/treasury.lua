
function DeduceFileTypeFromPath(path)
local str

str=filesys.extn(path)
if strutil.strlen(str) ==0 then return("ssl.csv") end

if str==".csv" then return("csv") end
if str==".xml" then return("xml") end
if str==".json" then return("json") end
if str==".zcsv" then return("zip.csv") end
if str==".zxml" then return("zip.xml") end
if str==".zjson" then return("zip.json") end
if str==".zipcsv" then return("zip.csv") end
if str==".zipxml" then return("zip.xml") end
if str==".zipjson" then return("zip.json") end
if str==".7zcsv" then return("7zip.csv") end
if str==".7zxml" then return("7zip.xml") end
if str==".7zjson" then return("7zip.json") end
if str==".7zipcsv" then return("7zip.csv") end
if str==".7zipxml" then return("7zip.xml") end
if str==".7zipjson" then return("7zip.json") end
if str==".scsv" then return("ssl.csv") end
if str==".sxml" then return("ssl.xml") end
if str==".sjson" then return("ssl.json") end
if str==".sslcsv" then return("ssl.csv") end
if str==".sslxml" then return("ssl.xml") end
if str==".ssljson" then return("ssl.json") end

return(string.sub(extn, 2))
end

