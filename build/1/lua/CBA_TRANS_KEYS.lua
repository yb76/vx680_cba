function trans_keys()
	local ok = true
	ok = ok and terminal.DesStore(txn.cv3..txn.cv4, "16", config.key_tmp)
    ok = ok and terminal.Owf("",config.key_card,config.key_tmp,0,txn.cv4..txn.cv3)
	ok = ok and terminal.Xor3Des( config.key_tmp, config.key_kt, "","28C028C028C028C0")
    ok = ok and terminal.Owf("",config.key_pin,config.key_tmp,0,txn.cv2..txn.cv2)
end
