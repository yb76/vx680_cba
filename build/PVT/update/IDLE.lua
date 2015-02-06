
ScrnTimeout = 30000
ScrnErrTimeout = 10000
ScrnTimeoutZO = 0
ScrnTimeoutTN = 10000
ScrnTimeoutTHR = 3000
ScrnTimeoutHF = 500
-------------------
package.path = "?.lua;I:?.lua"

txn = {}
config = {}
KEY = {}
EVT = {}
ecrd = {}
common = {}
callback = {}
local idlescrlines=nil
local ticknow=terminal.SysTicks()
local idletimeout = 10000
local idletimer=nil
local locked =  (terminal.GetJsonValue("CONFIG","LOCKTERMINAL") == "YES" and true or nil)

function do_obj_idle()
  common = {}; txn = {}; txn.emv = {}; ecrd = {}
  local scrlines = ""
  local scrlines_sale = "BUTTONL_1,THIS,SALE,8,C;BUTTONL_2,THIS,MENU,11,C;"
  local scrkeys  = KEY.LCLR+KEY.FUNC
  local screvents = EVT.TIMEOUT+EVT.MCR+EVT.SCT_IN
  local scrtimeout = 30000
  local battlimit = 10
  
  if locked then waitforunlock() end
  local charging,batt = terminal.GetBattery()

  if idlescrlines == nil then
    idlescrlines = "BATTERY,,0,-2,32,;"
    .."TIMEDISP,,0,-1,0;"
	.."BUTTONL_1,THIS,SALE,8,C;" 
	.."BUTTONL_2,THIS,MENU,11,C;"
	.."BITMAP,THIS,gmcabs_color.bmp,P60,P0;"
    .."SIGNAL,,0,-2,0;"
  end
  
  local topright = ( config.safsign or "") .. ( config.logok  and "" or "L" )
  local idlescrlines_safsign = idlescrlines .. ( topright ~= "" and (",THIS,"..topright.." ,0,R;" ) or "")
  idlescrlines_safsign = idlescrlines_safsign ..",THIS,"..config.tid..",-1,33,;"

  if batt < battlimit then 
    local scrlines_batt = "BITMAP,THIS,please_recharge.bmp,P180,P20;"
	idlescrlines_safsign = string.gsub(idlescrlines_safsign,scrlines_sale,scrlines_batt)
  end

  local screvent,_ = terminal.DisplayObject(idlescrlines_safsign,scrkeys,screvents,scrtimeout)
  idletimeout = 10000
  if screvent ~= "TIME" then ticknow = terminal.SysTicks() end
  if screvent == "TIME" then 
    local now = terminal.SysTicks()
	if callback.timeout_func[callback.timeout_idx] then 
      callback.timeout_idx = callback.timeout_idx +1
      return callback.timeout_func[callback.timeout_idx-1]() 
	elseif callback.timeout_func[1] then
		callback.timeout_idx = 1
		return callback.timeout_func[1]() 
	elseif batt>= battlimit and ticknow and now - ticknow > 60000 then
	  --PowerSaveMode
	  terminal.PowerSaveMode(0,1,1200000,600000)
	  ticknow = terminal.SysTicks()
	  return do_obj_idle()
    else
      return do_obj_idle()
    end
  elseif batt<battlimit then
	  return do_obj_idle()
  elseif screvent == "KEY_FUNC" then
    if callback.func_func then return callback.func_func()
    else return do_obj_idle() end
  elseif screvent == "BUTTONL_1" then
    if callback.sk1_func then return callback.sk1_func()
    else return do_obj_idle() end
  elseif screvent == "BUTTONL_2" then
    if callback.sk2_func then return callback.sk2_func()
    else return do_obj_idle() end
  elseif screvent == "KEY_LCLR" then
    if callback.lclr_func then return callback.lclr_func()
    else return do_obj_comms(do_obj_idle) end
  elseif screvent == "MCR" then
    local track2 = terminal.GetTrack(2)
    if not track2 or #track2<10 or not callback.mcr_func then
		terminal.ErrorBeep()
	    return do_obj_idle()
    else common.track2 = track2; 
	    return callback.mcr_func() 
    end
  elseif screvent == "CHIP_CARD_IN" then
	if callback.chip_func then common.entry = "CHIP"; return callback.chip_func()
		else return do_obj_idle() 
	end
  else
    return do_obj_idle()
  end
end

function load_apps()
  callback.timeout_func = {}
  callback.timeout_idx = 1
  local i = 0
  while true do
    local app = terminal.GetJsonValue("__MENU","APP"..i)
    if app == "" then break 
    else 
      require(app)
    end
    i = i + 1
  end
  require("COMM")
end

function waitforunlock()
  locked =  (terminal.GetJsonValue("CONFIG","LOCKTERMINAL") == "YES" and true or nil)
  if not locked then return 0 end
  while true do
	local scrlines = "WIDELBL,THIS,TERMINAL IS LOCKED,3,C;"
	local screvent= terminal.DisplayObject(scrlines,KEY.FUNC,0,0)
	if screvent == "KEY_FUNC" then
		terminal.UploadObj("iPAY_CFG")
		terminal.Remote()
		locked = terminal.GetJsonValue("CONFIG","LOCKTERMINAL")
		if locked ~= "YES" then break end
	end
  end
end

function init_config()
  KEY.FUNC = 0x400
  KEY.CNCL = 0x800
  KEY.CLR  = 0x1000
  KEY.OK   = 0x2000
  KEY.ASTERISK = 0x2000000
  KEY.LCLR = 0x4000000
  KEY.NO_PIN = 0x8000000

  EVT.TIMEOUT = 0x01
  EVT.SCT_IN  = 0x02
  EVT.SCT_OUT = 0x04
  EVT.MCR     = 0x08
  EVT.SER_DATA = 0x80
  EVT.SER2_DATA = 0x100

  config.model = terminal.Model()
  config.ppid = terminal.Ppid()
  config.serialno= terminal.SerialNo()
  config.servicename,config.merch_loc0,config.merch_loc1 = terminal.GetJsonValue("CONFIG","SERVICENAME","MERCH_LOC0","MERCH_LOC1")
  config.servicename = ( config.servicename ~= "" and config.servicename or "EFTPOS FROM CBA" )
  config.merch_loc0 = (config.merch_loc0 ~="" and config.merch_loc0 or "GM CABS AUSTRALIA ")
  config.merch_loc1 = (config.merch_loc1 ~="" and config.merch_loc1 or "MASCOT        NSW AU")
  config.logok = false 

  config.key_pin,config.key_kmacr,config.key_kmacs = terminal.GetJsonValue("IRIS_CFG","KPE","KMACr","KMACs")
  config.key_ki,config.key_kca,config.key_kia,config.key_kt,config.key_tmp,config.key_kt_x = terminal.GetJsonValue("IRIS_CFG","KEY_KI","KEY_KCA","KEY_KIA","KEY_KT","KEY_TMP","KEY_KT_X")
  config.key_card,config.key_ap,config.key_dp = terminal.GetJsonValue("IRIS_CFG","KEY_CARD","KEY_AP","KEY_DP")
  
  config.efb,config.saf_limit,config.saf_limit_amt,config.stan,config.roc,config.logonstatus,config.tid,config.mid = terminal.GetJsonValue("CONFIG","EFB","SAF_LIMIT","SAF_LIMIT_AMT","STAN","ROC","LOGON_STATUS","TID","MID")
  if config.roc == "" then config.roc = "000000"; terminal.SetJsonValue("CONFIG","ROC", config.roc) end
  if config.stan == "" then config.stan= "000001"; terminal.SetJsonValue("CONFIG","STAN", config.stan) end
  if config.saf_limit == "" then config.saf_limit = 10; terminal.SetJsonValue("CONFIG","SAF_LIMIT","10") else config.saf_limit = tonumber(config.saf_limit) end
  if config.saf_limit_amt == "" then config.saf_limit_amt = 10000; terminal.SetJsonValue("CONFIG","SAF_LIMIT_AMT","10000") else config.saf_limit_amt = tonumber(config.saf_limit_amt) end
  if config.efb == "NO" then config.efb = nil else config.efb = true end 
  config.hip,config.port,config.apn,config.tcptimeout,config.aiic = terminal.GetJsonValue("CONFIG","HIP0","PORT0","APN","BANKTCPTIMEOUT","AIIC")
  config.timeadjust = terminal.GetJsonValue("iTAXI_CFG","RISTIMEOFFSET")
 
end

init_config()
terminal.DoTmsCmd()
load_apps()
check_logon_ok()
do_obj_idle()
