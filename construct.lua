local tconcat = table.concat
local pack = table.pack or function ( ... ) return { n = select ( "#" , ... ) , ... } end

local function construct ( ... )
	local arg = pack ( ... )
	local str = {
		"*"..arg.n ;
	}
	for i = 1 , arg.n do
		local v = tostring ( arg[i] )
		str [ i*2 ] = "$" .. #v
		str [ i*2+1 ] = v
	end
	str [ #str+1 ] = ""
	return tconcat ( str , "\r\n" )
end

return construct
