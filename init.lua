local reader    = require "fend-redis.reader" ;
local reply     = require "fend-redis.reply" ;
local construct = require "fend-redis.construct" ;


-- Set up a global socket callback infrastructure
local newfifo = require "fifo"
local ffi = require "ffi"
require "fend.common"
include "string"

local function close_m ( m , err )
	-- Close all pipelined requests
	while true do
		local func = m.pipeline:pop ( )
		if not func then break end
		func ( nil , err )
	end
	-- Close all queued requests
	while true do
		local req = m.sendqueue:pop ( )
		if not req then break end
		req.callback ( nil , err )
	end
end

local file_map = { }

local BUFF_LEN = 16384
local buff = ffi.new ( "char[?]" , BUFF_LEN )

local redis_cbs = { }
function redis_cbs.read ( file , cbs )
	local m = file_map [ file ]
	while true do
		local c , err = m.sock:recv ( buff , BUFF_LEN )
		if not c then
			return cbs.close ( file , cbs )
		elseif c == 0 then
			break
		end
		m.reader:Feed ( buff , c )
		for reply in m.reader:GetReplies ( ) do
			local func = m.pipeline:pop ( )
			local reply , text = reply:toLua ( )
			if func ( reply , text ) == false then
				return cbs.close ( file , cbs )
			end
		end
	end
end
function redis_cbs.write ( file , cbs )
	local m = file_map [ file ]
	while true do
		local req = m.sendqueue:pop ( )
		if not req then break end

		local ok , err = m.sock:send ( req.data )
		if not ok then
			req.callback ( nil , err )
			return cbs.close ( file , cbs )
		else
			m.pipeline:push ( req.callback )
		end
	end
	-- Nothing more to write
	cbs.write = nil
	m.dispatch:add_fd ( file , m.cbs )
end
function redis_cbs.close ( file , cbs )
	local m = file_map [ file ]
	close_m ( m , "closed" )
	m.dispatch:del_fd ( file , cbs )
	m.sock:close ( )
	file_map [ file ] = nil
end
function redis_cbs.error ( file , cbs )
	local m = file_map [ file ]
	local err = m.sock:get_error ( )
	close_m ( m , err )
	m.dispatch:del_fd ( file , cbs )
	m.sock:close ( )
	file_map [ file ] = nil
end

local function add_sock ( dispatch , sock )
	local file = sock:getfile ( )
	local sendqueue = newfifo ( )
	sendqueue:setempty ( function ( ) return nil end )
	local pipeline = newfifo ( )
	pipeline:setempty ( function ( ) return nil end )
	local m = {
		dispatch  = dispatch ;
		sock      = sock ;
		reader    = reader.Create ( ) ;
		sendqueue = sendqueue ;
		pipeline  = pipeline ;
		cbs       = {
			read  = redis_cbs.read ;
			close = redis_cbs.close ;
			error = redis_cbs.error ;
			edge  = true ;
		}
	}
	file_map [ file ] = m
	dispatch:add_fd ( file , m.cbs )

	return function ( cb , ... )
			local req = {
				data     = construct ( ... ) ;
				callback = cb ;
			}
			if not m.cbs.write then
				m.cbs.write = redis_cbs.write
				m.dispatch:add_fd ( m.sock:getfile ( ) , m.cbs )
			end
			m.sendqueue:push ( req )
		end
end

return {
	reader    = reader ;
	reply     = reply ;
	construct = construct ;

	add_sock  = add_sock ;
}
