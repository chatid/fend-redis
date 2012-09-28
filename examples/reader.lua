local fend_redis = require "fend-redis"

reader = fend_redis.reader.Create ( )
reader:Feed "+OK\r\n:4\r\n*3\r\n$3\r\nSET\r\n$5\r\nmykey\r\n$7\r\nmyvalue\r\n"
for reply in reader:GetReplies ( ) do
	print ( reply )
end
