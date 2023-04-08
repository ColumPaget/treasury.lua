
function ReadToPassword(S)
local str

str=S:readto(":")
while str ~= nil
do
if string.find(str, "password") ~= nil then return str end
str=S:readto(":")
end

return nil
end

