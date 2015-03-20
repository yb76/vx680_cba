local ScrnTimeout = 30000
local ScrnErrTimeout = 3000

local KEY,EVT={},{}
local SKmanPKtcuMOD = nil
local SKmanPKtcuEXP = nil
local SKtcu = nil
local SKtcu_M = nil
local SKtcu_E = nil
local Ppid_bank = nil
local loadingStep = 0

function init_config()
  KEY.CNCL = 0x800
  KEY.CLR  = 0x1000
  KEY.OK   = 0x2000
  EVT.SER_DATA = 0x80
end

function do_obj_keys_init()
  local ret = terminal.SerConnect("","0","10","100","19200","8","N","1","")
  local ppid = terminal.Ppid()
  if ppid ~= "" then return do_obj_keys_done()
  else 
	terminal.SecInit()
	return do_obj_keys_wait()
  end
end

function do_obj_keys_wait()
  local scrlines = "WIDELBL,LOCAL_T,6,4,C;" .. "WIDELBL,LOCAL_T,200,6,C;"
  local screvent,_ = terminal.DisplayObject(scrlines,KEY.CNCL,EVT.SER_DATA,0)
  if screvent == "CANCEL" then
	terminal.Reboot()
  elseif screvent == "SER_DATA" then
	local serdata = terminal.SerRecv("")
	return do_obj_keys(serdata)
  end
end

function processMsg(serdata)
	local ok = true
	local msg = ""
	local sheader = string.sub(serdata,1,2)
	if sheader and sheader == "02" then
		msg = string.sub(serdata,3,#serdata)
		local lrc= string.sub(msg,-2)
		msg = string.sub(msg,1,#msg-2)
		if string.sub(msg,-2) ~= "03" then ok = false end
		msg = string.sub(msg,1,#msg-2)
	elseif sheader and sheader == "06" then
		return ok
	else
		ok = false
	end
	if not ok then return false end
	local scmd = terminal.StringToHex(string.sub(msg,1,4))
	if scmd == "01" then --logon command
	  local respcode = "00"
	  if loadingStep >= 1 then respcode = "03" end
	  local resp = terminal.HexToString(scmd..respcode )
	  local lrc = getLRC(resp)
	  terminal.SerSend("","06" .. "02".. resp .."03"..lrc) 
	  loadingStep = 1 
	elseif scmd == "A2" then --Set SKtcu
		msg = string.sub(msg,5,#msg)

		local part_ind = string.sub(msg,1,2)
		local key_x = string.sub(msg,3,#msg)
		local key_s = terminal.StringToHex(key_x)

		if part_ind == "30" then SKtcu_E = base64_hex(key_s) else SKtcu_M = base64_hex(key_s) end

		if SKtcu_E and SKtcu_M and string.len(SKtcu_E) + string.len(SKtcu_M) == 480 then
				SKtcu = "7878"..SKtcu_M ..SKtcu_E.."000000000000" -- mod_length(b960) + exp_length(b960) + mod + exp + padding
		end

		local resp = terminal.HexToString(scmd..(ok and "00" or "01"))
		resp = resp.. part_ind .. key_x

		local lrc = getLRC(resp)
		terminal.SerSend("","06" .. "02".. resp .."03"..lrc) 

 	  	loadingStep = 2 
	elseif scmd == "A3" then --Set sSKman(PKtcu)
		msg = string.sub(msg,5,#msg)

		local part_ind = string.sub(msg,1,2)
		local key_x = string.sub(msg,3,#msg)
		local key_s = terminal.StringToHex(key_x)

		if part_ind == "30" then SKmanPKtcuEXP = base64_hex(key_s) else SKmanPKtcuMOD = base64_hex(key_s) end

		if SKmanPKtcuMOD and string.len(SKmanPKtcuMOD) ~= 256  then
			SKmanPKtcuMOD = nil
		end
		if SKmanPKtcuEXP and string.len(SKmanPKtcuEXP) ~= 256  then
			SKmanPKtcuEXP = nil
		end

		local resp = terminal.HexToString(scmd..(ok and "00" or "01"))
		resp = resp.. part_ind .. key_x

		local lrc = getLRC(resp)
		terminal.SerSend("","06" .. "02".. resp .."03"..lrc) 
	  	loadingStep = 3 
	elseif scmd == "A0" then --Get Serial Number
		ok = true
		local resp = terminal.HexToString(scmd..(ok and "00" or "01").. string.sub(terminal.SerialNo(),-8))

		local lrc = getLRC(resp)
		terminal.SerSend("","06" .. "02".. resp .."03"..lrc) 
		loadingStep = 4 
	elseif scmd == "A1" then --Set PPID
		msg = string.sub(msg,5,#msg)

		local ppid = terminal.StringToHex(msg)
		if ppid and string.len(ppid) == 16 then Ppid_bank = ppid end
		
		local resp = terminal.HexToString(scmd..(ok and "00" or "01")).. msg

		local lrc = getLRC(resp)
		terminal.SerSend("","06" .. "02".. resp .."03"..lrc) 

		loadingStep = 5 
	elseif scmd == "0F" then --logoff
		loadingStep = 6 
		terminal.SerSend("","06" )
	end

	return true

end

function do_obj_keys(serdata_in)
  local ok = true
  ok = processMsg(serdata_in)
--	RIS KEY
  ok = ok and SKmanPKtcuMOD and SKmanPKtcuEXP and SKtcu and Ppid_bank and ( loadingStep == 6 )
  
  if not ok then
	return do_obj_keys_wait()
  else 
	return do_obj_keys_done()
  end
end

function do_obj_keys_done()
  local hip,port,apn = "192.168.110.70","6503","TNSICOMAU2"
  local jtable_s = "{TYPE:DATA,NAME:CONFIG,GROUP:CBA,VERSION:1,HIP0:"..hip..",PORT0:"..port..",APN:"..apn..",AIIC:560192}" 

  local master = terminal.GetJsonValue("IRIS_CFG","MASTER")
  if master~= ""  then terminal.DesStore("04040404040404040404040404040404","16",master) end
  terminal.NewObject("CONFIG",jtable_s)
  terminal.SetJsonValue("CONFIG","SKmanPKtcuMOD",SKmanPKtcuMOD )
  terminal.SetJsonValue("CONFIG","SKmanPKtcuEXP",SKmanPKtcuEXP )
  terminal.SetJsonValue("CONFIG","SKtcu",SKtcu )
  terminal.PpidUpdate(Ppid_bank)


  local ppid = terminal.Ppid()
  local scrlines = "WIDELBL,LOCAL_T,203,4,C;" .."WIDELBL,THIS,"..ppid..",6,C;"
  local screvent,scrinput = terminal.DisplayObject(scrlines,KEY.OK+KEY.CLR+KEY.CNCL,0,0)
  if screvent == "KEY_OK" then 
	terminal.Reboot()
  elseif screvent == "KEY_CLR" or screvent == "CANCEL" then
	terminal.PpidRemove()
	return do_obj_keys_wait()
  end
end

--
function getLRC(data)
	local lrc = terminal.LRCxor(data.."03")
	return lrc 
end

--base 64 decoding
function base64_hex(data)
	local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
	data = string.gsub(data, '[^'..b..'=]', '')
	return (data:gsub('.', function(x)
		if (x == '=') then return '' end
		local r,f='',(b:find(x)-1)
		for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
		return r;
	end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
		if (#x ~= 8) then return '' end
		local c=0
		for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
		return string.format("%02X",c)
	end))
end


init_config()
do_obj_keys_init()
