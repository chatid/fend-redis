local ffi = require "ffi"
local hiredis = require "fend-redis.lib"
local defines = hiredis.defines
local lib     = hiredis.lib
local reply   = require "fend-redis.reply"

local reader_mt = {
	__index = {
		Feed = function ( self , buff , len )
			if type ( buff ) == "string" then
				len = len or #buff
				buff = ffi.cast ( "const char*" , buff )
			end
			local r = lib.redisReaderFeed ( self , buff , len )
			if r ~= defines.REDIS_OK then
				error ( ffi.string ( self.errstr ) )
			end
			return true
		end ;
		GetReply = function ( self )
			local reply_p = ffi.new ( "redisReply*[1]" )
			local r = lib.redisReaderGetReply ( self , ffi.cast("void**",reply_p) ) ;
			if r ~= defines.REDIS_OK then
				error ( ffi.string ( self.errstr ) )
			end
			if reply_p[0] == nil then
				return nil
			else
				return ffi.gc ( reply_p[0] , lib.freeReplyObject )
			end
		end ;
		GetReplies = function ( self )
			return self.GetReply , self
		end
	} ;
	__tostring = function ( self )
		return "redisReader:{pos="..tostring(self.pos)..";len="..tostring(self.len)..";maxbuf="..tostring(self.maxbuf).."}"
	end ;
}
ffi.metatype ( "redisReader" , reader_mt )

local function Create ( )
	local reader = lib.redisReaderCreate ( )
	if reader == ffi.NULL then
		error ( "Unable to create redisReader" )
	end
	return ffi.gc ( reader , lib.redisReaderFree )
end

return {
	Create = Create ;
}
