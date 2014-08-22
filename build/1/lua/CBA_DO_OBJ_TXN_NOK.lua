function do_obj_txn_nok(tcperrmsg)
  local errcode,errmsg= "",""
  if not txn.rc then txn.rc = "W21" end
  if txn.tcperror then errcode,errmsg = tcperrorcode(tcperrmsg),tcperrmsg 
  else errcode,errmsg = txn.rc,txn.rc_desc or ""
    local rc = txn.rc
	if string.sub(txn.rc,1,1)~="Z" then rc = "H"..rc end
    errmsg = cba_errorcode(rc)
  end
  
  local scrlines = "WIDELBL,,120,2,C;"
  scrlines = scrlines.. "WIDELBL,THIS," .. (errmsg or "") ..",4,C;"
  terminal.ErrorBeep()
  terminal.DisplayObject(scrlines,0,EVT.TIMEOUT,ScrnTimeoutHF)
  if txn.rc and txn.rc == "98" then config.logok = false
	do_obj_txn_nok_print(errcode,errmsg,1)  
	check_logon_ok() 
	return do_obj_txn_finish()
  else return do_obj_txn_nok_print(errcode,errmsg)
  end
end
