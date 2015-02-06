--------------------------
local ScrnTimeout = 20000
local ScrnErrTimeout = 10000
local ScrnBootTimeout = 1000
package.path = "?.lua"
local KEY,EVT={},{}

function init_config()
  KEY.FUNC = 0x400
  KEY.CNCL = 0x800
  KEY.CLR  = 0x1000
  KEY.OK   = 0x2000
  KEY.LCLR = 0x4000000
  EVT.TIMEOUT = 0x01
end

function do_obj_boot()
  local ppid=terminal.Ppid()
  local srclines = "WIDELBL,THIS,PLEASE WAIT,4,C;"
  terminal.DisplayObject(srclines,0,0,0)
  
  if ppid =="" then
    terminal.SetNextObject("KEYS.lua")
    return 0
  else
	terminal.InitCommEng()
    local idx1,idx2,idx3=17,18,19
    local scrlines =  "LARGE,LOCAL_T,6,2,C;" .. "WIDELBL,LOCAL_T,"..idx1..",6,C;" .. "WIDELBL,LOCAL_T,"..idx2..",8,C;" .. ",LOCAL_T,"..idx3..",11,C;" .."TIMEDISP,,0,4,C;" 
    terminal.SetNextObject("SELF_TEST.lua")
    return 0
  end
end

init_config()
do_obj_boot()
