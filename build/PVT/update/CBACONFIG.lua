--
local ScrnTimeout = 30000
local ScrnErrTimeout = 10000

local KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6,KEY_7 =0x2,0x4,0x8,0x10,0x20,0x40,0x80

function do_obj_termconfig()
  local scrlines = "WIDELBL,,50,5,C;" .. "WIDELBL,,51,7,C;"
  local scrkeys = KEY_1+KEY_2+KEY_5+KEY_7+KEY.CNCL
  local screvents = EVT.TIMEOUT
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,screvents,ScrnTimeout)

  if screvent == "KEY_1" then
    return do_obj_tid()
  elseif screvent == "KEY_2" then
    return do_obj_mid()
  elseif screvent == "KEY_5" then
    return do_obj_comms_param()
  elseif screvent == "KEY_7" then
    return do_obj_print_param()
  else
    return do_obj_idle()
  end
end

function do_obj_termconfig_maintain()
  local scrlines = "WIDELBL,,50,5,C;" .. "WIDELBL,,52,7,C;"
  local scrkeys = KEY_1+KEY_2+KEY_3+KEY_4+KEY_5+KEY.CNCL
  local screvents = EVT.TIMEOUT
  local screvent,_ = terminal.DisplayObject(scrlines,scrkeys,screvents,ScrnTimeout)

  local screvent1

  if screvent == "KEY_1" then
    local scrlines = "WIDELBL,,60,5,C;" .. "WIDELBL,THIS,"..(config.tid or "")..",7,C;"
    local scrkeys = KEY.OK+KEY.CNCL
    screvent1 = terminal.DisplayObject(scrlines,scrkeys,screvents,ScrnTimeout)
	if screvent1 == "KEY_OK" then
		return do_obj_termconfig_maintain()
	elseif screvent1 == "CANCEL" or screvent1 == "TIME" then
		return do_obj_idle()
	end
  elseif screvent == "KEY_2" then
    local scrlines = "WIDELBL,,61,5,C;" .. "WIDELBL,THIS,"..(config.mid or "")..",7,C;"
    local scrkeys = KEY.OK+KEY.CNCL
    screvent1 = terminal.DisplayObject(scrlines,scrkeys,screvents,ScrnTimeout)
    if screvent1 == "KEY_OK" then
		return do_obj_termconfig_maintain()
	elseif screvent1 == "CANCEL" or screvent1 == "TIME" then
		return do_obj_idle()
	end
  elseif screvent == "KEY_3" then
    local ppid = terminal.Ppid()
    local scrlines = "WIDELBL,THIS,PPID,5,C;" .. "WIDELBL,THIS,"..(ppid or "")..",7,C;"
    local scrkeys = KEY.OK+KEY.CNCL
    screvent1 = terminal.DisplayObject(scrlines,scrkeys,screvents,ScrnTimeout)
    if screvent1 == "KEY_OK" then
		return do_obj_termconfig_maintain()
	elseif screvent1 == "CANCEL" or screvent1 == "TIME" then
		return do_obj_idle()
	end
  elseif screvent == "KEY_4" then
    local safmin,safmax = terminal.GetArrayRange("SAF")
	local cnt = safmax - safmin 
    local scrlines = "WIDELBL,THIS,SAF COUNT,5,C;" .. "WIDELBL,THIS,"..cnt..",7,C;"
    local scrkeys = KEY.OK+KEY.CNCL
    screvent1 = terminal.DisplayObject(scrlines,scrkeys,screvents,ScrnTimeout)
    if screvent1 == "KEY_OK" then
		return do_obj_termconfig_maintain()
	elseif screvent1 == "CANCEL" or screvent1 == "TIME" then
		return do_obj_idle()
	end
  elseif screvent == "KEY_5" then
	local appname = terminal.GetJsonValue("CONFIG","PAYMENTAPP_NAME")
	local appver = terminal.GetApplVer() or ""
	if appname == "" then appname = "CBA iPAY" end
    local scrlines = "WIDELBL,THIS,"..appname..",5,C;".. "WIDELBL,THIS,"..appver..",7,C;"
    local scrkeys = KEY.OK+KEY.CNCL
    screvent1 = terminal.DisplayObject(scrlines,scrkeys,screvents,ScrnTimeout)
    if screvent1 == "KEY_OK" then
		return do_obj_termconfig_maintain()
	elseif screvent1 == "CANCEL" or screvent1 == "TIME" then
		return do_obj_idle()
	end
  else
    return do_obj_idle()
  end
end

function do_obj_tid()
  local tid = terminal.GetJsonValue("CONFIG","TID")
    local scrlines = "LARGE,,60,5,C;" .. "LNUMBER,"..tid..",0,7,14,8,8;"
    local scrkeys = KEY.OK+KEY.CLR+KEY.CNCL
	local screvents = EVT.TIMEOUT
    local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,screvents,ScrnTimeout)

    if screvent == "KEY_CLR" then
      return do_obj_termconfig()
    elseif screvent == "KEY_OK" then
      if scrinput ~= tid then
        terminal.SetJsonValue("CONFIG","TID",scrinput)
        config.tid = scrinput
        terminal.SetJsonValue("iPAY_CFG","TID",scrinput)
        config.logok = false
		terminal.SetJsonValue("CONFIG","LOGON_STATUS","191")
		config.logonstatus = "191"
        return do_obj_termconfig()
      else return do_obj_termconfig() end
	else
		return do_obj_idle()
    end
end

function do_obj_mid()
  local mid = terminal.GetJsonValue("CONFIG","MID")
    local scrlines = "LARGE,,61,5,C;" .. "LNUMBER,"..mid..",0,7,8,15,15;"
    local scrkeys = KEY.OK+KEY.CLR+KEY.CNCL
	local screvents = EVT.TIMEOUT
    local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,screvents,ScrnTimeout)

    if screvent == "KEY_CLR" then
      return do_obj_termconfig()
    elseif screvent == "KEY_OK" then
      if scrinput ~= mid then
        terminal.SetJsonValue("CONFIG","MID",scrinput)
        config.mid = scrinput
        terminal.SetJsonValue("iPAY_CFG","MID",scrinput)
        config.logok = false
		terminal.SetJsonValue("CONFIG","LOGON_STATUS","191")
		config.logonstatus = "191"
        return do_obj_termconfig()
      else return do_obj_termconfig() end
	else
		return do_obj_idle()
    end
end
--7410
function do_obj_comms_param()
  local changed = false
  local hip,port,apn,tcptm = terminal.GetJsonValue("CONFIG","HIP0","PORT0","APN","BANKTCPTIMEOUT")
  local scrlines = ",THIS,BANK IP ADDRESS,5,C;" .. "STRING,"..hip..",,8,11,15,7;".."BUTTONA,THIS,ALPHA ,B,C;"
  local scrkeys = KEY.OK+KEY.CNCL+KEY.CLR
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  if screvent == "KEY_OK" then
		if scrinput ~= hip and #scrinput>0 then
			changed = true;config.hip = scrinput;terminal.SetJsonValue("CONFIG","HIP0",scrinput) 
		end
		scrlines = ",,223,5,C;" .. "STRING,"..port..",,8,17,5,1;"
		screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
		if screvent == "KEY_OK" then
		  if scrinput ~= port and #scrinput>0 then 
				changed = true;config.port = scrinput;terminal.SetJsonValue("CONFIG","PORT0",scrinput) 
			end
		  scrlines = ",,226,5,C;" .. "STRING,"..apn..",,8,8,19,1;".."BUTTONA,THIS,ALPHA ,B,C;"
		  screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
		  if screvent == "KEY_OK" then
			if scrinput ~= apn and #scrinput>0 then 
					changed = true;config.apn = scrinput;terminal.SetJsonValue("CONFIG","APN",scrinput) 
			end
			if tcptm == "" then tcptm = "30" end
			scrlines = ",THIS,BANK TCP TIMEOUT,5,C;" .. "STRING,"..tcptm..",,8,8,19,1;"
			screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
			if scrinput ~= tcptm and #scrinput>0 then 
				config.tcptimeout = tonumber(scrinput);terminal.SetJsonValue("CONFIG","BANKTCPTIMEOUT",scrinput) 
			end
		  end
		end
  end
  if changed then do_obj_gprs_register() end
  return do_obj_termconfig()
end


function do_obj_print_param()
	local prtvalue= "\\CHOST PARAMETERS\\n\\4\\w------------------------------------------\\n" 
	terminal.Print(prtvalue,false)
	local moto,saflimit,tcptm = terminal.GetJsonValue("CONFIG","MOTO","SAF_LIMIT","BANKTCPTIMEOUT")
	local moto_flag = (moto == "NO" and "NO" or "YES")
	local saf_flag = (saflimit == "" and "10" or saflimit)
	local tm_flag = (tcptm == "" and "30" or tcptm)
	local prtlocalvalue = "\\4MOTO ENABLED:\\R"..moto_flag .."\\n"
	prtlocalvalue = prtlocalvalue.. "SAF LIMIT:\\R"..saf_flag.."\\n"
	prtlocalvalue = prtlocalvalue.. "TCP TIMEOUT:\\R"..tm_flag.."\\n"
	terminal.Print(prtlocalvalue,false)
	terminal.Print("\\4\\w------------------------------------------\\n\\n",true)
	return do_obj_termconfig()
end

