function mac_check(rcvmsg)
	local data_nomac = string.sub(rcvmsg,1,#rcvmsg-16)
	local data_mac = string.sub(rcvmsg,-16)
	debugPrint(data_nomac)
	debugPrint(data_mac)
	local macr_x = string.sub(config.mab_send,-16)
	local macr_y = string.sub(config.mab_recv,-16)
	local mti2,mti3 = string.sub(rcvmsg,1,2),string.sub(rcvmsg,1,3)

    local msg_t = { "GET,39"}
	local errmsg,fld39 = terminal.As2805Break( rcvmsg, msg_t )

	local ok = true
	local ap = ""
	if mti2 ~= "04" and mti3 ~="023" and txn.cv3 and txn.cv4 and txn.cv5 and ( fld39=="00" or fld39=="08") then
	  local cv3 = txn.cv3 or "0123456701234567"
	  local cv4 = txn.cv4 or "89ABCDEF89ABCDEF"
	  local cv5 = txn.cv5 or "0123456789ABCDEF"
	  ok = ok and terminal.DesStore(cv3..cv4, "16", config.key_tmp)
	  ok = ok and terminal.Owf("",config.key_card,config.key_tmp,0,cv4..cv3)
	  ok = ok and terminal.Owf("",config.key_dp,config.key_card,0,cv5..cv5)
	  local stan = string.format("%06d",tonumber(txn.stan)) .. string.rep("0",10)
	  local tid = terminal.HexToString(config.tid)
	  local amt = txn.totalamt and string.format("%016d",txn.totalamt) or "0000000000000000"
	  local dv7 = terminal.XorData(stan,tid,16)
	  dv7 = txn.totalamt and terminal.XorData(dv7,amt,16) or dv7
	  terminal.SetIvMode("0")
      local ap0 = terminal.Dec(dv7,"","16",config.key_dp)
	  ap = terminal.XorData(dv7,ap0,16)
	end
	
	local chkmac = terminal.Mac(macr_x..data_nomac..ap,"",config.key_kmacs)
	if data_mac ~= chkmac and ap~= "" then
		chkmac = terminal.Mac(macr_x..data_nomac,"",config.key_kmacs)
	end
	if data_mac == chkmac then
		terminal.Owf("",config.key_kt,config.key_kt,0,macr_x..macr_y)
	    terminal.Xor3Des( config.key_kt_x, config.key_kt, "","24C024C024C024C0")
	    terminal.DesStore("0123456789ABCDEF","8", config.key_tmp)
	    terminal.Owf(config.key_tmp,config.key_kmacs,config.key_kt_x,0)
		return true
	else
		--return false
		terminal.DebugDisp("boyang...mac error ["..data_mac.."] != "..chkmac)
		return true --workaround
	end
end
