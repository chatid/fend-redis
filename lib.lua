local ffi = require "ffi"
local common = require "fend.common"
common.add_current_module ( )
include "hiredis/hiredis"
include "hiredis/async"
local lib = ffi.load ( "hiredis" )

return {
	defines = defines ;
	lib     = lib ;
}
