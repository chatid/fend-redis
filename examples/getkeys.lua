local socket   = require "fend.socket"
require "fend.socket_helpers"
local dns      = require "fend.dns"
local dispatch = require "fend.epoll"()
local redis    = require "fend-redis"

local dontquit = true

local addrinfo = dns.lookup("127.0.0.1",6379)
local sock = socket.new_tcp ( addrinfo.ai_family )
sock:connect ( addrinfo , dispatch , function ( sock , err )
		assert ( sock , err )
		local red = redis.add_sock ( dispatch , sock )
		red:query ( function ( reply , err )
				reply = assert ( reply , err ):toLua ( )
				for i , v in ipairs ( reply ) do
					print ( v )
				end
				dontquit = false
			end , "KEYS" , "*" )
	end )

while dontquit do
	dispatch:dispatch ( )
end
