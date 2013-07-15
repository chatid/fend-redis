local reader    = require "fend-redis.reader" ;
local reply     = require "fend-redis.reply" ;
local construct = require "fend-redis.construct" ;

local newfifo   = require "fend-redis.fifo"

-- Set up a global socket callback infrastructure
local ffi = require "ffi"

local function clear_pipeline ( m , err )
	-- Close all pipelined requests
	while true do
		local func = m.pipeline:pop ( )
		if not func then break end
		func ( nil , err )
	end
end

local function clear_queued ( m , err )
	-- Close all queued requests
	while true do
		local req = m.sendqueue:pop ( )
		if not req then break end
		req.callback ( nil , err )
	end
end

local function close_m ( m , err )
	clear_pipeline ( m )
	clear_queued ( m )
end

local file_map = { }

local BUFF_LEN = 16384
local buff = ffi.new ( "char[?]" , BUFF_LEN )

local redis_cbs = { }
function redis_cbs.read ( sock , cbs )
	local m = file_map [ sock ]
	while true do
		local c , err = sock:recv ( buff , BUFF_LEN )
		if not c then
			return cbs.close ( sock , cbs )
		elseif c == 0 then
			break
		end
		m.reader:Feed ( buff , c )
		for reply in m.reader:GetReplies ( ) do
			local func = m.pipeline:pop ( )
			if func ( reply ) == false then
				return cbs.close ( sock , cbs )
			end
		end
	end
end
function redis_cbs.write ( sock , cbs )
	local m = file_map [ sock ]
	while true do
		local req = m.sendqueue:pop ( )
		if not req then break end

		local ok , err = sock:send ( req.data )
		if not ok then
			req.callback ( nil , err )
			return cbs.close ( sock , cbs )
		else
			m.pipeline:push ( req.callback )
		end
	end
	-- Nothing more to write
	cbs.write = nil
	m.dispatch:add_fd ( sock , m.cbs )
end
function redis_cbs.close ( sock , cbs )
	local m = file_map [ sock ]
	close_m ( m , "closed" )
	m.dispatch:del_fd ( sock )
	sock:close ( )
	file_map [ sock ] = nil
end
function redis_cbs.error ( sock , cbs )
	local m = file_map [ sock ]
	local err = sock:get_error ( )
	close_m ( m , err )
	m.dispatch:del_fd ( sock )
	sock:close ( )
	file_map [ sock ] = nil
end

local function cmd_cb ( ok , res )
	if not ok then
		error ( "Redis request failed: " .. res )
	end
end

local redis_methods = {
	query = function ( self , cb , ... )
		local req = {
			data     = construct ( ... ) ;
			callback = cb ;
		}
		if not self.cbs.write and self.dispatch then
			self.cbs.write = redis_cbs.write
			self.dispatch:add_fd ( self.sock , self.cbs )
		end
		self.sendqueue:push ( req )
		return self
	end ;
	cmd = function ( self , ... )
		return self:query ( cmd_cb , ... )
	end ;
	set_sock = function ( self , dispatch , sock )
		assert ( self.sock == nil , "Redis object already has socket associated" )
		self.sock     = sock
		self.dispatch = dispatch
		file_map [ sock ] = self
		dispatch:add_fd ( sock , self.cbs )
		return self
	end ;
}
local redis_mt = {
	__index = redis_methods ;
}

local function new ( )
	local sendqueue = newfifo ( )
	sendqueue:setempty ( function ( ) return nil end )
	local pipeline = newfifo ( )
	pipeline:setempty ( function ( ) return nil end )
	local m = setmetatable ( {
			dispatch  = nil ;
			sock      = nil ;
			reader    = reader.Create ( ) ;
			sendqueue = sendqueue ;
			pipeline  = pipeline ;
			cbs       = {
				read  = redis_cbs.read ;
				close = redis_cbs.close ;
				error = redis_cbs.error ;
				edge  = true ;
			} ;
		} , redis_mt )
	return m
end

local function add_sock ( dispatch , sock )
	local m = new ( )
	return m:set_sock ( dispatch , sock )
end

return {
	reader    = reader ;
	reply     = reply ;
	construct = construct ;

	new       = new ;
	add_sock  = add_sock ;
}
