

importer.csv_map_fields=function(self, field_map, fields)
local toks, tok, count, field
local fieldlist={}

count=0
toks=strutil.TOKENIZER(fields, ",")
tok=toks:next()
while tok ~= nil
do
	field=field_map[tok] 
	if field == nil then field="notes" end
	count=count + 1
  fieldlist[count]=field

tok=toks:next()
end

return fieldlist
end



importer.import_csv_line=function(self, box, line, fields)
local toks, tok, field
local key=""
local value=""
local notes=""
local count=1

toks=strutil.TOKENIZER(line, ",", "Q")

tok=toks:next()
while tok ~= nil
do
  field=self:map_field(fields, "", count)
  count=count+1

  if field == "key" then key=tok
  elseif field == "value" then value=tok
  else notes=notes.." "..tok
  end

tok=toks:next()
end

if strutil.strlen(key) > 0 
then
 box:add(key, value, notes) 
 self.items_imported=self.items_imported + 1
 return(true)
end

return(false)
end



importer.import_csv=function(self, box, doc)
local lines, line

lines=strutil.TOKENIZER(doc, "\n", "Q")

if self.fields_type=="map" then fields=self:csv_map_fields(self.fields, lines:next())
else fields=self.fields
end


--if no fieldlist supplied then assume first line of file is a fieldlist
if fields==nil then fields=self:read_fieldlist(lines:next()) end


line=lines:next()
while line ~= nil
do
	self:import_csv_line(box, line, fields) 
	line=lines:next()
end


end

