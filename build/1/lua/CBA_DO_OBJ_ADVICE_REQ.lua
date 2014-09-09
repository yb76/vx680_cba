function do_obj_advice_req()

  --[[
  --  0000 1000 0000 0010 0100 0010 0100 0000
  --  08024040
  --  01 10 31383030353039313833
  --  02 10 313830303530 39313833
  --  03 01 30
  --  04 01 60
  --  05 01 30
  --  06 01 30
  --  07 01 30
  --  08 01 10
  --  09 02 0030
  --  10 01 30
  --  11 06 000000000000
  --  12 06 000000000000
  --  31 01 01
  --  32 01 00
  --  33 06 000000000000
  --  34 01 30
  --  35 02 0100
  --  36 06 000000000000
  --  37 06 000000000000
  --  38 06 000000000000
  ]]--
  
  local fld63 = "08024040011031383030353039313833021031383030353039313833030130040160050130060130070130080110090200301001301106000000000000120600000000000031010132010033060000000000003401303502"..string.format("%04d",config.saf_limit or 10).."360600000000000037060000000000003806000000000000"

  local fld48 = terminal.HexToString("VX670   001A")  
  
  local fld71 = "0001"
  local fld72 = "0001"
  local msg_flds={"0:620","3:".. "950000","11:"..config.stan,"41:"..config.tid,"42:"..config.mid,"48:"..fld48,"63:"..fld63,"71:"..fld71,"72:"..fld72,"128:KEY="..config.key_kmacs}
  local as2805msg = terminal.As2805Make( msg_flds)
  local ok = true

  local retmsg = tcpsend(as2805msg)
  if retmsg ~= "NOERROR" then txn.tcperror = true; ok = false end
  if ok then retmsg,as2805msg = tcprecv() end
    if ok and retmsg ~= "NOERROR" then txn.tcperror = true; ok = false end
	if ok and (not as2805msg or as2805msg=="") then txn.tcperror = true; ok = false; retmsg = "NO_RESPONSE" end
	if not ok then return do_obj_txn_nok(retmsg)
    else
		local fld63 =""
		local msg_t = {"GETS,12","GETS,13","GETS,39","GETS,48","GETS,61","GETS,63"}

		local errmsg,fld12,fld13,fld39,fld48,fld61,fld63 = terminal.As2805Break( as2805msg, msg_t )
		
		if fld39 and #fld39>0 then txn.rc = fld39 end
		if fld39 ~="00" then return do_obj_txn_nok(fld39)
		else
			if #fld63 > 5 then terminal.SetJsonValue("0630","63",fld63) end
			local banktime = nil
			if fld12 and fld13 then banktime = fld13..fld12 end
			if banktime and string.len(banktime)  == 10 then
				local yyyymm = terminal.Time( "YYYYMM")
				local yyyy,mm = string.sub(yyyymm,1,4),string.sub(yyyymm,5,6)
				if mm == "01" and string.sub(banktime,1,2) == "12" then yyyy = tonumber(yyyy) -1 end
				if mm == "12" and string.sub(banktime,1,2) == "01" then yyyy = tonumber(yyyy) +1 end
				terminal.TimeSet(yyyy..banktime,config.timeadjust)
			end
			local timestr = terminal.Time( "DD/MM/YY hh:mm" )
			if txn.manuallogon then
  			  local prtdata = "\\C\\H" .. config.servicename .."\\n\\n" ..
                  "\\C" .. config.merch_loc0 .."\\n" ..
                  "\\C" .. config.merch_loc1 .."\\n" ..
                  "\\CSOFTWARE CHECK\\n\\n" ..
                  "MERCHANT ID:\\R" .. string.sub(config.mid,-8) .. "\\n" ..
                  "TERMINAL ID:\\R" .. config.tid .."\\n" ..
                  "DATE/TIME:\\R" .. timestr .. "\\n" ..
                  "BANK REF:\\R" .. string.format("%06d",txn.stan).. "\\n" ..
                  "APPROVED\\R00\\n" ..
				  "\\4------------------------------------------\\n"
		      terminal.Print(prtdata,true)
		      checkPrint(prtdata)
			end
			terminal.DebugDisp("boyang....1")
  			do_obj_saf_rev_start()
			terminal.DebugDisp("boyang....2")
        	return do_obj_txn_finish()
	  end
    end
end
