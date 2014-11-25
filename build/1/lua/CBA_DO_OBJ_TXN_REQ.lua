function do_obj_txn_req()
	local as2805msg,retmsg = prepare_txn_req()
	if retmsg then
		if  txn.chipcard and not txn.emv.fallback and not txn.earlyemv and not txn.ctls then
			txn.offline = true
			return do_obj_offline_check()
		else
			return do_obj_txn_nok(retmsg)
		end
	elseif as2805msg == "" then txn.tcperror = true 
		return do_obj_txn_nok(retmsg)
	else
		if terminal.FileExist("TXN_REQ") then
			local fld0 = terminal.GetJsonValue("TXN_REQ","0")
			if fld0 == "200" then
				local revfile = "REV_TODO"
				local ret = terminal.FileCopy( "TXN_REQ", revfile)
				if txn.cardname == "VISA" and txn.emv.tlv and #txn.emv.tlv > 0 then 
					local newtlv = txn.emv.tlv .. terminal.EmvPackTLV("9F5B")
					terminal.SetJsonValue(revfile,"55",newtlv)
				end
			end
		end

		retmsg = tcpsend(as2805msg)
		if retmsg ~= "NOERROR" then 
			if retmsg == "NO_RESPONSE" or retmsg == "TIMEOUT" then copy_txn_to_saf() end
			if  txn.chipcard and not txn.ctls and not txn.emv.fallback and not txn.earlyemv then
				txn.offline = true
				return do_obj_offline_check()
			elseif (retmsg == "NO_RESPONSE" or retmsg == "TIMEOUT" or retmsg =="TESTING") and check_efb() then
				txn.rc = "00" 
				txn.efb = true
				generate_saf()
				return do_obj_txn_ok()
			else 
				txn.tcperror = true 
				return do_obj_txn_nok(retmsg)
			end
		else return do_obj_txn_resp()
		end
	end
end
