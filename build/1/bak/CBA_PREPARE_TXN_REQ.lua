function prepare_txn_req()
    local msg_flds = {}
	local msgid = txn.rc and txn.rc == "Y1" and "220" or "200"
	txn.mti = msgid
    local proccode = "00"

	local retmsg = nil
	local rev_exist = config.safsign and string.find(config.safsign,"+")
	if msgid == "200" and rev_exist then
		local rev_sent = do_obj_saf_rev_send("REVERSAL") 
		if not rev_sent then retmsg = "REVERSAL PENDING" end
  		local pan = txn.fullpan
		--get_trans_cv(pan)
		trans_keys()
		txn.pinblock = terminal.PinBlockCba(config.key_card,config.key_pin,pan,"0")
	end
	
    if txn.func == "PRCH" then proccode = "00" end
    table.insert(msg_flds,"0:"..msgid)
    if txn.pan then table.insert(msg_flds,"2:"..txn.pan) end
    if txn.account == "SAVINGS" then proccode = proccode .. "1000"
    elseif txn.account == "CHEQUE" then proccode = proccode .. "2000"
    elseif txn.account == "CREDIT" then proccode = proccode .. "3000" end
    table.insert(msg_flds,"3:" .. proccode)
    table.insert(msg_flds,"4:" .. tostring(txn.totalamt))
    table.insert(msg_flds,"11:" .. config.stan)
    if msgid == "220" then
      local mmddhhmmss = terminal.Time( "MMDDhhmmss")
      table.insert(msg_flds,"13:"..string.sub(mmddhhmmss,1,4))
      table.insert(msg_flds,"12:"..string.sub(mmddhhmmss,5,10))
    end
    if txn.expiry then table.insert(msg_flds,"14:"..string.sub(txn.expiry,3,4)..string.sub(txn.expiry,1,2)) end
    local posentry = ""
    if txn.pan  then posentry = "01"
	elseif txn.ctls and not txn.chipcard then posentry = "81"
	elseif txn.chipcard and txn.emv.fallback then posentry = "62"
    elseif txn.chipcard and txn.ctls then posentry = "07"
	elseif txn.chipcard and txn.emv.pan then posentry = "05"
    elseif txn.track2  then posentry = "02"
    end

	local cvmr = txn.chipcard and not txn.earlyemv and not txn.emv.fallback and not txn.ctls and terminal.EmvGetTagData(0x9f34)
	cvmr = cvmr and string.sub(cvmr,2,2)
	if cvmr then
		if cvmr == "1" or cvmr == "3" or cvmr == "4" or cvmr == "5" then
			txn.offlinepin = true 
		end 
	end
	if txn.chipcard and txn.offlinepin then
	    posentry = posentry .. "9"
	else
		posentry = posentry .. "1"
	end
	
    table.insert(msg_flds,"22:" .. posentry)
    if txn.chipcard and txn.emv.panseqnum then table.insert(msg_flds,"23:" .. txn.emv.panseqnum) end
    if txn.poscc == nil then txn.poscc = "42" end
    table.insert(msg_flds,"25:" .. txn.poscc)
    if txn.track2 then table.insert(msg_flds,"35:" .. txn.track2)
    elseif txn.chipcard and txn.emv.track2 then table.insert(msg_flds,"35:" .. txn.emv.track2) end
    table.insert(msg_flds,"41:" ..config.tid)
    table.insert(msg_flds,"42:" ..config.mid)
    local fld47 = ""
    local tcc = "07"
	
    if txn.ccv then fld47 = fld47 ..txn.ccv  end
    fld47 = fld47 .. "TCC" ..tcc.."\\"
    table.insert(msg_flds,"47:" ..terminal.HexToString(fld47))
    
    if txn.pinblock and #txn.pinblock > 0 then 
		table.insert(msg_flds,"52:" ..txn.pinblock) 
	end
    if txn.chipcard and not txn.earlyemv and not txn.emv.fallback then
	  local t9f53 =""
	  local tlvs = ""
	  if txn.ctls == "CTLS_E" then
			local EMV5000 = ""
			local EMV9f02 = ""
			local EMV9f03 = ""
			local EMV9f26 = ""
			local EMV8200 = ""
			local EMV9f36 = ""
			local EMV9f34 = ""
			local EMV9f27 = ""
			local EMV9f1e = ""
			local EMV9f10 = ""
			local EMV9f33 = ""
			local EMV9f1a = ""
			local EMV9500 = ""
			local EMV5f2a = ""
			local EMV9a00 = ""
			local EMV9c00 = ""
			local EMV9f35 = ""
			local EMV9f37 = ""
			local EMV8400 = ""
			local tagvalue = ""

			tagvalue = get_value_from_tlvs("5000")
			EMV5000 = "50".. string.format("%02X",#tagvalue/2) .. tagvalue
			tagvalue = get_value_from_tlvs("9F02")
			EMV9f02 = "9F02"..string.format("%02X",#tagvalue/2)  .. tagvalue
			tagvalue = get_value_from_tlvs("9F03")
			if tagvalue =="" then tagvalue = "000000000000" end
			EMV9f03 = "9F03"..string.format("%02X",#tagvalue/2)  .. tagvalue
			tagvalue = get_value_from_tlvs("9F26")
			EMV9f26 = "9F26"..string.format("%02X",#tagvalue/2) .. tagvalue
			tagvalue = get_value_from_tlvs("8200")
			EMV8200 = "82".. string.format("%02X",#tagvalue/2) .. tagvalue
			tagvalue = get_value_from_tlvs("9F36")
			EMV9f36 = "9F36"..string.format("%02X",#tagvalue/2)  .. tagvalue
			tagvalue = get_value_from_tlvs("9F34")
			EMV9f34 = "9F34"..string.format("%02X",#tagvalue/2)  .. tagvalue
			tagvalue = get_value_from_tlvs("9F27")
			EMV9f27 = "9F27"..string.format("%02X",#tagvalue/2)  .. tagvalue
  			EMV9f1e = "9F1E08"..terminal.HexToString(string.sub(config.serialno,-8))
			tagvalue = get_value_from_tlvs("9F10")
			EMV9f10 = "9F10"..string.format("%02X",#tagvalue/2)  .. tagvalue
			tagvalue = get_value_from_tlvs("9F33")
			if tagvalue == "" then tagvalue = "0008C8" end
			EMV9f33 = "9F33"..string.format("%02X",#tagvalue/2) .. tagvalue
			tagvalue = get_value_from_tlvs("9F1A")
			EMV9f1a = "9F1A"..string.format("%02X",#tagvalue/2)  .. tagvalue
			tagvalue = get_value_from_tlvs("9500")
			EMV9500 = "95".. string.format("%02X",#tagvalue/2) .. tagvalue
			tagvalue = get_value_from_tlvs("5F2A")
			EMV5f2a = "5F2A"..string.format("%02X",#tagvalue/2)  .. tagvalue
			tagvalue = get_value_from_tlvs("9A00")
			EMV9a00 = "9A".. string.format("%02X",#tagvalue/2) .. tagvalue
			tagvalue = get_value_from_tlvs("9C00")
			EMV9c00 = "9C".. string.format("%02X",#tagvalue/2) .. tagvalue
			tagvalue = get_value_from_tlvs("9F35")
			if tagvalue == "" then tagvalue = "22" end
			EMV9f35 = "9F35"..string.format("%02X",#tagvalue/2)  .. tagvalue
			tagvalue = get_value_from_tlvs("9F37")
			EMV9f37 = "9F37"..string.format("%02X",#tagvalue/2) .. tagvalue
			tagvalue = get_value_from_tlvs("8400")
			EMV8400 = "84"..string.format("%02X",#tagvalue/2) .. tagvalue

			tlvs=tlvs..EMV9f02..EMV9f03..EMV9f26..EMV8200..EMV9f36..EMV9f34..EMV9f27..EMV9f1e..EMV9f10..EMV9f33..EMV9f1a..EMV9500..EMV5f2a..EMV9a00..EMV9c00..EMV9f35..EMV9f37..EMV8400
	  else
      tlvs = terminal.EmvPackTLV("9F02".."9F03".."9F26".."8200".."9F36".."9F34".."9F27".."9F10".."9F33".."9F1A".."9500".."5F2A".."9A00".."9C00".."9F35".."9F37".."8400").."9F1E08"..terminal.HexToString(string.sub(config.serialno,-8))
	  end
      txn.emv.tlv = tlvs
      table.insert(msg_flds,"55:" ..tlvs)
    end
	
	
     terminal.DesStore(txn.cv1,"8", config.key_tmp) 
     terminal.Owf(config.key_tmp,config.key_kmacs,config.key_kt_x ,0)
	 
    table.insert(msg_flds,"64:KEY=" .. config.key_kmacs)
    local as2805msg = terminal.As2805Make( msg_flds)

    if as2805msg ~= "" then
      local txnstr = "{TYPE:DATA,NAME:TXN_REQ,GROUP:CBA,VERSION:1,ROC:"..config.roc.."," .. table.concat(msg_flds,",") .."}"
      terminal.NewObject("TXN_REQ",txnstr)
    end
    return as2805msg,retmsg
end
