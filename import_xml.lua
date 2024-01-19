require("xml")

importer.import_xml_item=function(self, box, XML)
local tok
local item={}

tok=XML:next()
while tok ~= nil
do
if tok.type=="name" then item.name=XML:next().data
elseif tok.type=="value" then item.value=XML:next().data
elseif tok.type=="notes" then item.notes=XML:next().data
elseif tok.type=="type" then item.type=XML:next().data
elseif tok.type=="updated" then item.updated=XML:next().data
elseif tok.type=="/item" then break 
end

tok=XML:next()
end

box:add_item(item) 
self.items_imported=self.items_imported + 1

end



importer.import_xml=function(self, box, doc)
local XML, tok

XML=xml.XML(doc)
tok=XML:next()
while tok ~= nil
do
if tok.type=="item" then self:import_xml_item(box, XML) end
tok=XML:next()
end

end
