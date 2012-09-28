local socket   = require "fend.socket"
require "fend.socket_helpers"
local dns      = require "fend.dns"
local dispatch = require "fend.epoll"()
local redis    = require "fend-redis"

local dontquit = true

local addrinfo = dns.lookup("127.0.0.1",6379)
local sock = socket.new_tcp ( addrinfo.ai_family )
sock:connect ( addrinfo , dispatch , function ( sock , err )
		if not sock then
			print ( "ERROR Connecting: " .. err )
			dontquit = false
			return
		end
		local redis_cmd = redis.add_sock ( dispatch , sock )
		redis_cmd ( function ( reply , err )
				for i , v in ipairs ( reply ) do
					print ( v )
				end
				dontquit = false
			end , "KEYS" , "*" )
	end )

while dontquit do
	dispatch:dispatch ( )
end
