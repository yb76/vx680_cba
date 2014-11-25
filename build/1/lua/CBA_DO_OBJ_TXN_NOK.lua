function do_obj_txn_nok(tcperrmsg)
  local errcode,errmsg,errline2 = "","",""
  if not txn.rc then txn.rc = "W21" end
  if txn.tcperror then errcode,errmsg = tcperrorcode(tcperrmsg),tcperrmsg 
  else errcode,errmsg = txn.rc, ""
    local rc = txn.rc
	if string.sub(txn.rc,1,1)~="Z" then rc = "H"..rc end
    errmsg = cba_errorcode(rc)
  end
  local evt,itimeout = EVT.TIMEOUT, ScrnTimeoutHF
  
  if txn.ctls and txn.rc == "65" then 
	errline2 = "WIDELBL,THIS,PLEASE INSERT CARD,4,C;"
	evt = EVT.SCT_IN+EVT.TIMEOUT
	itimeout = 15000
  end
  
  local scrlines = "WIDELBL,,120,2,C;"
  scrlines = scrlines.. "WIDELBL,THIS," .. (errmsg or "") ..",4,C;"..errline2
  terminal.ErrorBeep()
  local screvent =terminal.DisplayObject(scrlines,KEY.CLR+KEY.CNCL+KEY.OK,evt,itimeout)
  if txn.rc and txn.rc == "98" then config.logok = false
	do_obj_txn_nok_print(errcode,errmsg,1)  
	check_logon_ok() 
	return do_obj_txn_finish()
  elseif screvent == "CHIP_CARD_IN" then 
  	do_obj_txn_nok_print(errcode,errmsg,1)
	terminal.FileRemove("TXN_REQ")
	terminal.FileRemove("REV_TODO")
    return do_obj_idle()
  else return do_obj_txn_nok_print(errcode,errmsg)
  end
end
