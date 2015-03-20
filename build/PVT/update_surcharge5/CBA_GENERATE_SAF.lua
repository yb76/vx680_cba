function generate_saf()
	local safmin,safnext = terminal.GetArrayRange("SAF")
	local saffile = "SAF"..safnext
	terminal.FileCopy("TXN_REQ", saffile)
	terminal.SetJsonValue(saffile,"0","220")
	terminal.SetJsonValue(saffile,"39",txn.rc or "00")
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
