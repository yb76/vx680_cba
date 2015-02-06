function copy_txn_to_saf()
	if terminal.FileExist("TXN_REQ") then
		local fld0 = terminal.GetJsonValue("TXN_REQ","0")
		if fld0 == "200" then
			local safmin,safnext = terminal.GetArrayRange("REVERSAL")
			local saffile = "REVERSAL"..safnext
			local ret = terminal.FileCopy( "TXN_REQ", saffile)
			if txn.cardname == "VISA" and txn.emv.tlv and #txn.emv.tlv > 0 then 
				local newtlv = txn.emv.tlv .. terminal.EmvPackTLV("9F5B")
				terminal.SetJsonValue(saffile,"55",newtlv)
			end
			terminal.SetArrayRange("REVERSAL","",safnext+1)
		end
	end
end
