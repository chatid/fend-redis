local ffi = require "ffi"
local hiredis = require "fend-redis.lib"
local defines = hiredis.defines
local lib     = hiredis.lib

local type_converters = {
	[defines.REDIS_REPLY_STATUS] = function ( self )
		local status_str = ffi.string ( self.str , self.len )
		return true , status_str
	end ;
	[defines.REDIS_REPLY_ERROR] = function ( self )
		local error_str = ffi.string ( self.str , self.len )
		return false , error_str
	end ;
	[defines.REDIS_REPLY_INTEGER] = function ( self )
		return self.integer
	end ;
	[defines.REDIS_REPLY_NIL] = function ( self )
		return nil
	end ;
	[defines.REDIS_REPLY_STRING] = function ( self )
		return ffi.string ( self.str , self.len )
	end ;
	[defines.REDIS_REPLY_ARRAY] = function ( self )
		local t = { }
		local nelems = tonumber(self.elements)
		for i=1,nelems do
			t [ i ] = self.element [ i-1 ]:toLua ( )
		end
		return t
	end ;
}

local function toLua ( reply )
	return type_converters [ reply.type ] ( reply )
end ;

local reply_mt = {
	__index = {
		toLua = toLua ;
	} ;
	__tostring = function ( self )
		local v = toLua ( self )
		if type ( v ) == "table" then
			return "redisReply:multibulk"
		else
			return tostring ( v )
		end
	end ;
}
ffi.metatype ( "redisReply" , reply_mt )

return {
	toLua = toLua ;
}
