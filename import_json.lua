
importer.import_json_item=function(self, box, item)
local keyname, valuename, notesname, updatedname, key, value, notes, updated

keyname=self.fields["key"]
valuename=self.fields["value"]
notesname=self.fields["notes"]
updatedname=self.fields["updated"]

key=item:value(keyname)
value=item:value(valuename)
notes=item:value(notesname)
updated=item:value(updatedname)

box:add(key, value, notes, updated)
self.items_imported=self.items_imported + 1
end


importer.import_json_subitems=function(self, box, parent)
local items, item

if parent == nil then return end

items=parent:subitems()
item=items:next()
while item ~= nil
do
	self:import_json_iterate(box, item)
	item=items:next()
end

end


importer.import_json_iterate=function(self, box, item)

if item == nil then return end

if item:type() == "array" then self:import_json_subitems(box, item)
else self:import_json_item(box, item)
end

end


importer.import_json=function(self, box, doc)
local P, items, item

items=dataparser.PARSER("json", doc)
if items ~= nil
then
	self:import_json_subitems(box, items:open("/"))
end

end


