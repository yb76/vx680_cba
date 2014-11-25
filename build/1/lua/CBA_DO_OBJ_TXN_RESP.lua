function do_obj_txn_resp()
  local scrlines = "WIDELBL,,27,2,C;" .. "WIDELBL,,26,4,C;"
  terminal.DisplayObject(scrlines,0,0,ScrnTimeoutZO)
  local rcvmsg,errmsg,fld12,fld13,fld15,fld37,fld38,fld39,fld44,fld47,fld48,fld55,fld64
  errmsg, rcvmsg = tcprecv()
  if errmsg == "MAC" or errmsg == "NO_RESPONSE" or errmsg == "TIMEOUT" then copy_txn_to_saf() end

  if errmsg == "MAC" then 
	 txn.tcperror = true
	 return do_obj_txn_nok("MAC") -- mac error
  elseif errmsg ~= "NOERROR" or not rcvmsg or rcvmsg == "" then 
	if errmsg == "NOERROR" then errmsg = "NO_RESPONSE" end
	if  txn.chipcard and not txn.emv.fallback and not txn.earlyemv and not txn.ctls then
		txn.offline = true
		return do_obj_offline_check()
	elseif errmsg == "TIMEOUT" and check_efb() then
		txn.rc = "00" 
		txn.efb = true
		generate_saf()
		return do_obj_txn_ok()
	else txn.tcperror = true
		return do_obj_txn_nok(errmsg)
	end
  else
    txn.host_response = true
    local msg_t = {"GET,12","GET,13","GET,15","GETS,37","GETS,38","GETS,39","GETS,48","GETS,55","GETS,64" }
    errmsg,fld12,fld13,fld15,fld37,fld38,fld39,fld48,fld55,fld64 = terminal.As2805Break( rcvmsg, msg_t )
    if fld12 and fld13 then txn.time = fld13..fld12 end
    if fld38 and #fld38>0 then txn.authid = fld38 end
    if fld39 and #fld39>0 then txn.rc = fld39 end

    if errmsg ~= "NOERROR" then return do_obj_txn_nok(errmsg)  -- as2805 error
	elseif fld39 == "91" and txn.chipcard and not txn.emv.fallback and not txn.earlyemv and not txn.ctls then
		txn.offline = true
		return do_obj_offline_check()
	elseif fld39 == "91" and check_efb() then
		txn.rc = "00" 
		txn.efb = true
		generate_saf()
		return do_obj_txn_ok()
    elseif fld39 ~= "00" and fld39 ~= "08" then 
      local HOST_DECLINED = 2
      if not txn.ctls and txn.chipcard and not txn.emv.fallback and not txn.earlyemv then terminal.EmvUseHostData(HOST_DECLINED,fld55) end
      return do_obj_txn_nok(errmsg)
    else 
      if txn.time and string.len(txn.time)  == 10 then
        local yyyymm = terminal.Time( "YYYYMM")
        local yyyy,mm = string.sub(yyyymm,1,4),string.sub(yyyymm,5,6)
        if mm == "01" and string.sub(txn.time,1,2) == "12" then yyyy = tonumber(yyyy) -1 end
        if mm == "12" and string.sub(txn.time,1,2) == "01" then yyyy = tonumber(yyyy) +1 end
		txn.time = yyyy..txn.time
        terminal.TimeSet(txn.time,config.timeadjust)
      end
      local HOST_AUTHORISED,emvok = 1,0

      if not txn.ctls and txn.chipcard and not txn.emv.fallback and not txn.earlyemv then
		local rc = terminal.HexToString(txn.rc)
		terminal.EmvSetTagData(0x8A00,rc)
		emvok = terminal.EmvUseHostData(HOST_AUTHORISED,fld55) 
		if txn.emvrcpt then
			local tsi = terminal.EmvGetTagData(0x9B00)
			local tsi_s = "TSI:\\R".. tsi.."\\n"
			txn.emvrcpt = string.gsub(txn.emvrcpt, "TSI:\\R....\\n",tsi_s )
		end
	  end
      if emvok ~= 0--[[TRANS_DECLINE]] then 
        local safmin,safnext = terminal.GetArrayRange("REVERSAL")
        local saffile = "REVERSAL"..safnext
        local ret = terminal.FileCopy( "TXN_REQ", saffile)
		txn.rc = "Z4"
		if txn.cardname == "VISA" and txn.emv.tlv and #txn.emv.tlv > 0 then 
			terminal.EmvSetTagData(0x8A00,terminal.HexToString(txn.rc))
			local newtlv = txn.emv.tlv .. terminal.EmvPackTLV("9F5B")
			terminal.SetJsonValue(saffile,"55",newtlv)
		end
        terminal.SetArrayRange("REVERSAL","",tostring(safnext+1))
        return do_obj_txn_nok(txn.rc) 
      else
		return do_obj_txn_ok() 
	  end
    end
  end
end
