function do_obj_offline_check()
  if toomany_saf() then 
	txn.rc = "W30"
	txn.tcperror = true
	return do_obj_txn_nok("SAF LIMIT EXCEEDED")
  else
	local FAILED_TO_CONNECT = 3
	local ret = terminal.EmvUseHostData(FAILED_TO_CONNECT,"")
	if ret == 0 then 
		txn.rc = "Y3"
		--prepare 0220
		if txn.func ~= "AUTH" then
			local safmin,safnext = terminal.GetArrayRange("SAF")
			local saffile = "SAF"..safnext
			terminal.FileCopy("TXN_REQ", saffile)
			terminal.SetJsonValue(saffile,"0","220")
			terminal.SetJsonValue(saffile,"39",txn.rc)
			local mmddhhmmss = terminal.Time("MMDDhhmmss")
			terminal.SetJsonValue(saffile,"12",string.sub(mmddhhmmss,5,10))
			terminal.SetJsonValue(saffile,"13",string.sub(mmddhhmmss,1,4))
			
			if txn.cardname == "VISA" and txn.emv.tlv and #txn.emv.tlv > 0 then 
				terminal.EmvSetTagData(0x8A00,terminal.HexToString(txn.rc))
				local newtlv = txn.emv.tlv .. terminal.EmvPackTLV("8A009F5B")
				terminal.SetJsonValue(saffile,"55",newtlv)
			end
			terminal.SetJsonValue(saffile,"ROC",config.roc)
			terminal.SetArrayRange("SAF","",tostring(safnext+1))
			txn.saf_generated = true
		end
		return do_obj_txn_ok()
	else
		txn.rc = "Z3"
		return do_obj_txn_nok(txn.rc)
	end
  end
end
